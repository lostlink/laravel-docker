#!/bin/bash
# shellcheck disable=SC2016

set -e
#set -x

# Write environment variables to /usr/local/bin/.mailparse.env
echo "Writing environment variables to /usr/local/bin/.mailparse.env"
cat <<EOF > /usr/local/bin/.mailparse.env
export KINESIS_STREAM_NAME="${KINESIS_STREAM_NAME:-}"
export KINESIS_REGION="${KINESIS_REGION:-}"
export WEBHOOK_URL="${WEBHOOK_URL:-}"
export FORWARD_EMAIL="${FORWARD_EMAIL:-}"
export DOMAIN_FILTER="${DOMAIN_FILTER:-msg.domaineasy.com}"
export LOG_FILE="${LOG_FILE:-/var/log/email_pipe.log}"
export LOG_MAX_SIZE="${LOG_MAX_SIZE:-1048576}"
EOF

# Ensure the .mailparse.env file is readable
chmod +r /usr/local/bin/.mailparse.env

echo "Create config file from template"
. /usr/local/bin/venv/bin/activate
envtpl < /etc/pdns/recursor.conf.tpl > /etc/pdns/recursor.conf

echo "Create PowerDNS directories"
mkdir -p /var/run/pdns-recursor

echo "Set PowerDNS permissions"
chown -R pdns /etc/pdns/recursor.conf /etc/pdns/recursor.d /etc/pdns/zones /var/run/pdns-recursor

echo "Prepare Postfix CatchAll Aliases"
postalias /etc/aliases

echo "Postfix needs fresh copies of files in its chroot jail"
cp /etc/{hosts,localtime,nsswitch.conf,resolv.conf,services} /var/spool/postfix/etc/

if [ "$1" != "" ]; then
  exec "$@"
else
  opendmarc
  opendkim
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi

