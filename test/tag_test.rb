# frozen_string_literal: true

require "test_helper"

class TagTest < ActiveSupport::TestCase
  setup { configure(site_id: "pa_TEST123456", enabled: true) }

  test "prints the basic snippet" do
    assert_equal '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456"></script>',
                 PrivatusAnalytics::Tag.new.to_s
  end

  test "prints nothing without a site id" do
    configure(site_id: nil)

    assert_equal "", PrivatusAnalytics::Tag.new.to_s
  end

  test "prints nothing outside the enabled environments" do
    configure(enabled: nil)

    assert_equal "", PrivatusAnalytics::Tag.new.to_s
  end

  test "adds modules and exclusions" do
    configure(modules: %w[engage auto], excluded_paths: ["/admin/*", "/preview/*"])
    tag = PrivatusAnalytics::Tag.new.to_s

    assert_includes tag, 'data-modules="engage,auto"'
    assert_includes tag, 'data-exclude="/admin/*,/preview/*"'
  end

  test "an empty modules list loads none" do
    configure(modules: [])

    assert_includes PrivatusAnalytics::Tag.new.to_s, 'data-modules=""'
  end

  test "adds domains, spa mode and manual mode" do
    configure(domains: "example.com, www.example.com", spa: "hash", manual: true)
    tag = PrivatusAnalytics::Tag.new.to_s

    assert_includes tag, 'data-domains="example.com,www.example.com"'
    assert_includes tag, 'data-spa="hash"'
    assert_includes tag, 'data-manual="true"'
  end

  test "ignores an unknown spa mode and the auto default" do
    configure(spa: "bogus")

    refute_includes PrivatusAnalytics::Tag.new.to_s, "data-spa"
  end

  test "escapes attribute values" do
    configure(excluded_paths: ['/a"b'])

    assert_includes PrivatusAnalytics::Tag.new.to_s, 'data-exclude="/a&quot;b"'
  end

  test "per call options override the configuration" do
    configure(modules: %w[engage])

    assert_includes PrivatusAnalytics::Tag.new(PrivatusAnalytics.configuration, modules: %w[vitals]).to_s,
                    'data-modules="vitals"'
  end

  test "adds extra attributes and a nonce" do
    configure(extra_attributes: { "data-mask" => "/orders/*->/orders/:id" })
    tag = PrivatusAnalytics::Tag.new(PrivatusAnalytics.configuration, nonce: "abc123").to_s

    assert_includes tag, 'data-mask="/orders/*-&gt;/orders/:id"'
    assert_includes tag, 'nonce="abc123"'
  end
end
