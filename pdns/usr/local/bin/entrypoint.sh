#!/bin/sh

set -euo pipefail

# Configure mysql env vars
: "${PDNS_AUTH_gmysql_one_host:=${MYSQL_ENV_MYSQL_HOST:-mysql}}"
: "${PDNS_AUTH_gmysql_one_port:=${MYSQL_ENV_MYSQL_PORT:-3306}}"
: "${PDNS_AUTH_gmysql_one_user:=${MYSQL_ENV_MYSQL_USER:-root}}"
if [ "${PDNS_AUTH_gmysql_one_user}" = 'root' ]; then
    : "${PDNS_AUTH_gmysql_one_password:=${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-}}"
fi
: "${PDNS_AUTH_gmysql_one_password:=${MYSQL_ENV_MYSQL_PASSWORD:-powerdns}}"
: "${PDNS_AUTH_gmysql_one_dbname:=${MYSQL_ENV_MYSQL_DATABASE:-powerdns}}"

# use first part of node name as database name suffix
if [ "${NODE_NAME:-}" ]; then
    NODE_NAME=$(echo ${NODE_NAME} | sed -e 's/\..*//' -e 's/-//')
    PDNS_AUTH_gmysql_one_dbname="${PDNS_AUTH_gmysql_one_dbname}${NODE_NAME}"
fi


export PDNS_AUTH_gmysql_one_host PDNS_AUTH_gmysql_one_port PDNS_AUTH_gmysql_one_user PDNS_AUTH_gmysql_one_password PDNS_AUTH_gmysql_one_dbname

EXTRA=""

# Password Auth
if [ "${PDNS_AUTH_gmysql_one_password}" != "" ]; then
    EXTRA="${EXTRA} -p${PDNS_AUTH_gmysql_one_password}"
fi

# Allow socket connections
if [ "${PDNS_AUTH_gmysql_one_socket:-}" != "" ]; then
    export PDNS_AUTH_gmysql_one_host="localhost"
    EXTRA="${EXTRA} --socket=${PDNS_AUTH_gmysql_one_socket}"
fi

MYSQL_COMMAND="mysql -h ${PDNS_AUTH_gmysql_one_host} -P ${PDNS_AUTH_gmysql_one_port} -u ${PDNS_AUTH_gmysql_one_user}${EXTRA}"

# Wait for MySQL to respond
until $MYSQL_COMMAND -e ';' ; do
    >&2 echo "MySQL is unavailable - sleeping: ${MYSQL_COMMAND}"
    sleep 3
done

# Initialize DB if needed
if [ "${SKIP_DB_CREATE:-false}" != 'true' ]; then
    $MYSQL_COMMAND -e "CREATE DATABASE IF NOT EXISTS ${PDNS_AUTH_gmysql_one_dbname}"
fi

MYSQL_CHECK_IF_HAS_TABLE="SELECT COUNT(DISTINCT table_name) FROM information_schema.columns WHERE table_schema = '${PDNS_AUTH_gmysql_one_dbname}';"
MYSQL_NUM_TABLE=$($MYSQL_COMMAND --batch --skip-column-names -e "$MYSQL_CHECK_IF_HAS_TABLE")
if [ "$MYSQL_NUM_TABLE" -eq 0 ]; then
    $MYSQL_COMMAND -D "$PDNS_AUTH_gmysql_one_dbname" < /usr/share/doc/pdns/schema.mysql.sql
fi

# SQL migration to version 4.7
MYSQL_CHECK_IF_47="SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = '${PDNS_AUTH_gmysql_one_dbname}' AND table_name = 'domains' AND column_name = 'options';"
MYSQL_NUM_TABLE=$($MYSQL_COMMAND --batch --skip-column-names -e "$MYSQL_CHECK_IF_47")
if [ "$MYSQL_NUM_TABLE" -eq 0 ]; then
    echo 'Migrating MySQL schema to version 4.7...'
    $MYSQL_COMMAND -D "$PDNS_AUTH_gmysql_one_dbname" < /usr/share/doc/pdns/4.3.0_to_4.7.0_schema.mysql.sql
fi

if [ "${PDNS_AUTH_superslave:-no}" = "yes" ]; then
    # Configure supermasters if needed
    if [ "${SUPERMASTER_IPS:-}" ]; then
        $MYSQL_COMMAND -D "$PDNS_AUTH_gmysql_one_dbname" -e "TRUNCATE supermasters;"
        MYSQL_INSERT_SUPERMASTERS=''
        if [ "${SUPERMASTER_COUNT:-0}" = "0" ]; then
            SUPERMASTER_COUNT=10
        fi
        i=1; while [ $i -le ${SUPERMASTER_COUNT} ]; do
            SUPERMASTER_HOST=$(echo ${SUPERMASTER_HOSTS:-} | awk -v col="$i" '{ print $col }')
            SUPERMASTER_IP=$(echo ${SUPERMASTER_IPS} | awk -v col="$i" '{ print $col }')
            if [ -z "${SUPERMASTER_HOST:-}" ]; then
                SUPERMASTER_HOST=$(hostname -f)
            fi
            if [ "${SUPERMASTER_IP:-}" ]; then
                MYSQL_INSERT_SUPERMASTERS="${MYSQL_INSERT_SUPERMASTERS} INSERT INTO supermasters VALUES('${SUPERMASTER_IP}', '${SUPERMASTER_HOST}', 'admin');"
            fi
            i=$(( i + 1 ))
        done
        $MYSQL_COMMAND -D "$PDNS_AUTH_gmysql_one_dbname" -e "$MYSQL_INSERT_SUPERMASTERS"
    fi
fi

# Create config file from template
. /root/venv/bin/activate
envtpl < /pdns.conf.tpl > /etc/pdns/pdns.conf
envtpl < /recursor.conf.tpl > /etc/pdns/recursor.conf

mkdir -p /var/run/pdns-recursor

chown -R pdns /etc/pdns/recursor.conf /etc/pdns/recursor.d /etc/pdns/zones /var/run/pdns-recursor

#if [ "$1" != "" ]; then
#  exec "$@"
#else
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
#fi