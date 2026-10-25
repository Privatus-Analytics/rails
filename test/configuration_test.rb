# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  test "site id is nil by default" do
    assert_nil PrivatusAnalytics.configuration.site_id
  end

  test "site id falls back to the environment variable" do
    ENV["PRIVATUS_SITE_ID"] = "pa_FROMENV123"

    assert_equal "pa_FROMENV123", PrivatusAnalytics.configuration.site_id
  end

  test "an explicit site id wins over the environment variable" do
    ENV["PRIVATUS_SITE_ID"] = "pa_FROMENV123"
    configure(site_id: "pa_EXPLICIT01")

    assert_equal "pa_EXPLICIT01", PrivatusAnalytics.configuration.site_id
  end

  test "script host defaults and drops a trailing slash" do
    assert_equal "https://privatusstats.com", PrivatusAnalytics.configuration.script_host
    configure(script_host: "https://stats.example.com/")

    assert_equal "https://stats.example.com", PrivatusAnalytics.configuration.script_host
  end

  test "only production is enabled by default" do
    config = PrivatusAnalytics.configuration

    assert config.enabled?("production")
    refute config.enabled?("development")
    refute config.enabled?("test")
  end

  test "enabled forces the tag on or off" do
    configure(enabled: true)

    assert PrivatusAnalytics.configuration.enabled?("development")
    configure(enabled: false)

    refute PrivatusAnalytics.configuration.enabled?("production")
  end

  test "the Rails config object is the gem configuration" do
    assert_same PrivatusAnalytics.configuration, Rails.application.config.privatus_analytics
  end

  test "props and queue stub are off by default" do
    config = PrivatusAnalytics.configuration

    assert_empty config.page_props
    refute config.queue_stub
  end

  test "page props call a lambda with the request, or one with no arguments" do
    configure(props: ->(request) { { path: request } })

    assert_equal({ path: "/a" }, PrivatusAnalytics.configuration.page_props("/a"))
    configure(props: -> { { plan: "pro" } })

    assert_equal({ plan: "pro" }, PrivatusAnalytics.configuration.page_props("/a"))
  end

  test "page props treat nil from the lambda as no props" do
    configure(props: ->(_request) {})

    assert_empty PrivatusAnalytics.configuration.page_props
  end
end
