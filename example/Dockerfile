# Conformance example app (a tiny Rails app). Build with the gem folder as the
# context: docker build -f example/Dockerfile .
FROM ruby:3.4.7-slim-bookworm
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends build-essential libyaml-dev \
  && rm -rf /var/lib/apt/lists/*
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test
# The gem from this repo's own source (path: ".." in the Gemfile).
WORKDIR /pkg
COPY privatus-analytics-rails.gemspec ./
COPY lib/privatus_analytics/version.rb lib/privatus_analytics/
COPY example/Gemfile example/
WORKDIR /pkg/example
RUN bundle install --jobs 4 --quiet
COPY . /pkg
EXPOSE 8080
CMD ["sh", "-c", "exec bundle exec puma --bind tcp://0.0.0.0:${PORT:-8080} --threads 1:4 config.ru"]
