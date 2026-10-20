# frozen_string_literal: true

require_relative "lib/privatus_analytics/version"

Gem::Specification.new do |spec|
  spec.name = "privatus-analytics-rails"
  spec.version = PrivatusAnalytics::VERSION
  spec.authors = ["Two Phase LLC"]
  spec.email = ["james@privatusanalytics.com"]

  spec.summary = "Cookieless Privatus Analytics tracking script for Rails."
  spec.description = "Adds the Privatus Analytics tracking script to your Rails views with a helper " \
                     "or an optional Rack middleware. The script sets no cookies, so analytics does " \
                     "not need a consent banner by itself."
  spec.homepage = "https://privatusanalytics.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "homepage_uri" => "https://privatusanalytics.com",
    "source_code_uri" => "https://github.com/Privatus-Analytics/rails",
    "changelog_uri" => "https://github.com/Privatus-Analytics/rails/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/Privatus-Analytics/rails/issues",
    "documentation_uri" => "https://privatusanalytics.com/docs",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "actionview", ">= 6.1", "< 9"
  spec.add_dependency "railties", ">= 6.1", "< 9"
end
