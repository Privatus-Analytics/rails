# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require_relative "dummy/config/environment"
require "rails/test_help"
require "minitest/autorun"

class ActiveSupport::TestCase
  setup do
    PrivatusAnalytics.reset_configuration!
    ENV.delete("PRIVATUS_SITE_ID")
    ENV.delete("PRIVATUS_SCRIPT_HOST")
  end

  teardown do
    PrivatusAnalytics.reset_configuration!
    ENV.delete("PRIVATUS_SITE_ID")
    ENV.delete("PRIVATUS_SCRIPT_HOST")
  end

  private

  def configure(**settings)
    settings.each { |name, value| PrivatusAnalytics.configuration.public_send(:"#{name}=", value) }
  end
end
