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

  test "page props print an inline script before the tag and data-props on it" do
    html = PrivatusAnalytics::Tag.new(PrivatusAnalytics.configuration, props: { plan: "pro", role: "admin" }).to_s

    props_script = '<script>window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>'
    tracker = '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456" ' \
              'data-props="privatusPageProps"></script>'

    assert_equal "#{props_script}\n#{tracker}", html
  end

  test "the props script gets the nonce" do
    html = PrivatusAnalytics::Tag.new(PrivatusAnalytics.configuration, props: { plan: "pro" }, nonce: "abc").to_s

    assert html.start_with?('<script nonce="abc">window.privatusPageProps=')
  end

  test "empty props print no script and no data-props" do
    html = PrivatusAnalytics::Tag.new(PrivatusAnalytics.configuration, props: { plan: nil }).to_s

    refute_includes html, "privatusPageProps"
  end

  test "configured props can be a hash" do
    configure(props: { plan: "pro" })

    assert_includes PrivatusAnalytics::Tag.new.to_s, '{"plan":"pro"}'
  end

  test "configured props can be a lambda that gets the request" do
    configure(props: ->(request) { { plan: request.fetch(:plan) } })
    tag = PrivatusAnalytics::Tag.new(PrivatusAnalytics.configuration, request: { plan: "team" })

    assert_includes tag.to_s, '{"plan":"team"}'
  end

  test "per call props are merged over configured props and nil removes one" do
    configure(props: { plan: "pro", role: "admin" })
    html = PrivatusAnalytics::Tag.new(PrivatusAnalytics.configuration, props: { role: nil, tier: "gold" }).to_s

    assert_includes html, '{"plan":"pro","tier":"gold"}'
  end

  test "the props lambda is not called when the tag is off" do
    configure(enabled: false, props: ->(_request) { raise "should not run" })

    assert_equal "", PrivatusAnalytics::Tag.new.to_s
  end

  test "queue stub prints the official stub first" do
    configure(queue_stub: true)
    html = PrivatusAnalytics::Tag.new(PrivatusAnalytics.configuration, nonce: "abc", props: { plan: "pro" }).to_s
    parts = html.split("\n")

    assert_equal %(<script nonce="abc">#{PrivatusAnalytics::Tag::QUEUE_STUB}</script>), parts[0]
    assert_includes parts[1], "privatusPageProps"
    assert_includes parts[2], "/js/pa.js"
  end

  test "the queue stub is the official one" do
    assert_equal "window.privatus=window.privatus||{q:[]};['track','pageview','props','optOut','optIn','ready']" \
                 ".forEach(function(m){window.privatus[m]=window.privatus[m]||function(){window.privatus.q.push(" \
                 "[m,Array.prototype.slice.call(arguments)])}})", PrivatusAnalytics::Tag::QUEUE_STUB
  end

  test "queue stub can be switched on per call" do
    assert_includes PrivatusAnalytics::Tag.new(PrivatusAnalytics.configuration, queue_stub: true).to_s, "q:[]"
    refute_includes PrivatusAnalytics::Tag.new.to_s, "q:[]"
  end
end
