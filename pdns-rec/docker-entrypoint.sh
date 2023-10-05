#!/bin/sh

set -euo pipefail

# Create config file from template
envtpl < /recursor.conf.tpl > /etc/pdns/recursor.conf

mkdir -p /var/run/pdns-recursor

chown -R recursor: /etc/pdns/recursor.conf /etc/pdns/recursor.d /etc/pdns/zones /var/run/pdns-recursor

exec "$@"
