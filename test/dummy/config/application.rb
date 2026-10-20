# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "privatus-analytics-rails"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "test-secret-key-base-for-the-dummy-app-only"
    config.hosts.clear
    config.logger = Logger.new(nil)
    config.active_support.deprecation = :stderr
  end
end
