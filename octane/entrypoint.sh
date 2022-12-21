#!/usr/bin/env bash
set -e

php() {
  su octane -c "php $*"
}

initialStuff() {
    php artisan optimize:clear; \
    php artisan package:discover --ansi; \
    php artisan event:cache; \
    php artisan config:cache; \
    php artisan route:cache;
}

if [ "$1" != "" ]; then
    exec "$@"
else
    initialStuff
    exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.web.conf
    exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.horizon.conf
    exec supercronic /etc/supercronic/laravel
fi
