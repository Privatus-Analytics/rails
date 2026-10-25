# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "privatus-analytics-rails"

# Conformance example app for privatus-analytics-rails.
module ConformanceExample
  # The conformance suite (https://github.com/Privatus-Analytics/conformance)
  # builds this app and checks every route in a real browser; see its
  # CONTRACT.md. The site id and script host come from PRIVATUS_SITE_ID and
  # PRIVATUS_SCRIPT_HOST.
  class Application < Rails::Application
    config.load_defaults 8.0
    config.root = File.expand_path("..", __dir__)
    config.eager_load = true
    config.secret_key_base = "conformance-example-only-not-a-secret"
    config.logger = ActiveSupport::Logger.new($stdout)
    config.log_level = :info
    config.hosts.clear

    # Forced on, so the tag prints in any environment.
    config.privatus_analytics.enabled = true

    script_host = ENV.fetch("PRIVATUS_SCRIPT_HOST", "https://privatusstats.com").chomp("/")
    config.content_security_policy do |policy|
      policy.script_src script_host
    end
    config.content_security_policy_nonce_generator = ->(_request) { "testnonce" }
    config.content_security_policy_nonce_directives = %w[script-src]
  end
end
