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

startSupervisord() {
  if [ -z "${APP_ENV}" ]; then
      echo "Variable APP_ENV does not exist or is empty!"
      echo "Setting default value to Production"
      export APP_ENV=production
  fi

  if [ "${APP_ENV,,}" == "local" ]; then
    echo "Starting container in: ${APP_ENV} mode"
    export OCTANE_PROD=false;
    export OCTANE_DEV=true;
  else
    echo "Starting container in: ${APP_ENV} mode"
    export OCTANE_PROD=true;
    export OCTANE_DEV=false;
  fi

  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}

# Run the initial setup
initialStuff

# Start Supervisord in the background
startSupervisord &

# Check if HORIZON_WORKER is set to "true"
if [ "${HORIZON_WORKER}" == "true" ]; then
  # Start the loop to monitor the PHP command
  while true; do
      result=$(su octane -c "php artisan tinker --execute=\"echo \Illuminate\Support\Facades\Queue::size('default');\"")
      if [ "$result" -eq 0 ]; then
          echo "Queue size is 0. Stopping Supervisord programs."
          supervisorctl stop all
          exit 0
          break
      else
          echo "Queue size is $result. Waiting for it to reach 0..."
          sleep 5
      fi
  done
else
  echo "HORIZON_WORKER is not set to 'true'. The queue monitoring loop will not run."
fi

# Wait for both processes to finish
wait