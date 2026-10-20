#!/bin/sh
# Runs tests, RuboCop and gem build in a pinned Ruby image. Usage: ./run-docker.sh
set -e
docker run --rm -v "$PWD":/app -w /app ruby:3.4.7-slim-bookworm sh -c '
  apt-get update -qq >/dev/null && apt-get install -y -qq build-essential git >/dev/null 2>&1
  bundle install -j4 --quiet
  bundle exec rake test
  bundle exec rubocop
  gem build privatus-analytics-rails.gemspec
  rm -f privatus-analytics-rails-*.gem
'
