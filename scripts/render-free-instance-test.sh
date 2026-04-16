#!/usr/bin/env bash
set -e

bundle exec sidekiq -C config/sidekiq.yml &
SIDEKIQ_PID=$!

bundle exec puma -p $PORT -e ${RAILS_ENV:-production} &
PUMA_PID=$!

wait -n

echo "One process exited. Stopping everything..."
kill -TERM $SIDEKIQ_PID $PUMA_PID

exit 1