#!/bin/sh

set -euo pipefail

# Create config file from template
envtpl < /recursor.conf.tpl > /etc/pdns/recursor.conf

mkdir -p /var/run/pdns-recursor

chown recursor: /etc/pdns/recursor.conf /var/run/pdns-recursor

exec "$@"
