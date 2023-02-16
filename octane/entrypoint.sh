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
    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
    supercronic /etc/supercronic/laravel
    if [ "$ENABLE_HORIZON" = "true" ]; then supervisorctl start horizon; fi
    if [ "$ENABLE_SCHEDULER" = "true" ]; then supervisorctl start scheduler; fi
fi
