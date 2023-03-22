#!/usr/bin/env bash
set -e

php() {
  su octane -c "php $*"
}

initialStuff() {
    composer dump -o; \
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

  if [ -z "${APP_ENV}" ]; then
      echo "Variable APP_ENV does not exist or is empty!"
      echo "Setting default value to Production"
      export APP_ENV=production
  fi

  if [ "${APP_ENV,,}" == "production" ]; then
    echo "Starting container in: ${APP_ENV} mode"
    export OCTANE_PROD=true;
    export OCTANE_DEV=false;
  else
    echo "Starting container in: ${APP_ENV} mode"
    export OCTANE_PROD=false;
    export OCTANE_DEV=true;
  fi

  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi
