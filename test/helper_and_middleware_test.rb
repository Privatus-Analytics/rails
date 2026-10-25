# frozen_string_literal: true

require "test_helper"

class HelperAndMiddlewareTest < ActionDispatch::IntegrationTest
  SNIPPET = '<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_TEST123456"></script>'

  test "the helper prints the tag in the layout head" do
    configure(site_id: "pa_TEST123456", enabled: true)
    get "/"

    assert_response :success
    assert_includes response.body, SNIPPET
    assert_operator response.body.index(SNIPPET), :<, response.body.index("</head>")
  end

  test "the helper prints nothing in the test environment by default" do
    configure(site_id: "pa_TEST123456")
    get "/"

    refute_includes response.body, "pa.js"
  end

  test "the helper prints nothing without a site id" do
    configure(enabled: true)
    get "/"

    refute_includes response.body, "pa.js"
  end

  test "the middleware does nothing by default" do
    configure(site_id: "pa_TEST123456", enabled: true)
    get "/plain"

    refute_includes response.body, "pa.js"
  end

  test "the middleware adds the tag to the head when switched on" do
    configure(site_id: "pa_TEST123456", enabled: true, auto_inject: true)
    get "/plain"

    assert_includes response.body, "#{SNIPPET}\n</head>"
    assert_equal response.body.bytesize.to_s, response.headers["Content-Length"]
  end

  test "the middleware does not add a second tag when the layout has one" do
    configure(site_id: "pa_TEST123456", enabled: true, auto_inject: true)
    get "/"

    assert_equal 1, response.body.scan("/js/pa.js").size
  end

  test "the middleware leaves JSON alone" do
    configure(site_id: "pa_TEST123456", enabled: true, auto_inject: true)
    get "/data"

    refute_includes response.body, "pa.js"
  end

  test "the middleware leaves HTML without a head alone" do
    configure(site_id: "pa_TEST123456", enabled: true, auto_inject: true)
    get "/bare"

    assert_equal "<p>No head here</p>", response.body
  end

  test "the middleware leaves Ajax requests alone" do
    configure(site_id: "pa_TEST123456", enabled: true, auto_inject: true)
    get "/plain", headers: { "X-Requested-With" => "XMLHttpRequest" }

    refute_includes response.body, "pa.js"
  end

  test "the middleware adds nothing outside the enabled environments" do
    configure(site_id: "pa_TEST123456", auto_inject: true)
    get "/plain"

    refute_includes response.body, "pa.js"
  end

  test "in development the layout prints only the queue stub when it is on" do
    configure(site_id: "pa_TEST123456", queue_stub: true, props: { plan: "pro" })
    get "/"

    assert_includes response.body, "<script>#{PrivatusAnalytics::Tag::QUEUE_STUB}</script>"
    refute_includes response.body, "pa.js"
    refute_includes response.body, "privatusPageProps"
  end

  test "event and click helpers render in a real view" do
    get "/features"

    assert_includes response.body,
                    '<button data-privatus-event="Export CSV" data-privatus-prop-format="csv">Export</button>'
    assert_includes response.body,
                    '<button data-privatus-event="Report shared" data-privatus-prop-via="link">Share</button>'
    assert_includes response.body, '<a data-privatus-click="pricing.cta" href="/pricing">Pricing</a>'
  end

  test "the layout tag sends configured props from the request" do
    configure(site_id: "pa_TEST123456", enabled: true, props: ->(request) { { plan: request.params[:plan] } })
    get "/", params: { plan: "pro" }

    assert_includes response.body, 'window.privatusPageProps=function(){return {"plan":"pro"}}'
    assert_includes response.body, 'data-props="privatusPageProps"'
  end

  test "the middleware calls the props lambda with a Rack request" do
    seen = nil
    props = lambda do |request|
      seen = request
      { section: request.path.delete_prefix("/") }
    end
    configure(site_id: "pa_TEST123456", enabled: true, auto_inject: true, props: props)
    get "/plain"

    assert_kind_of Rack::Request, seen
    assert_includes response.body, '{"section":"plain"}'
    assert_includes response.body, 'data-props="privatusPageProps"'
  end

  test "the middleware adds the CSP nonce and the queue stub" do
    configure(site_id: "pa_TEST123456", enabled: true, auto_inject: true, queue_stub: true, props: { plan: "pro" })
    get "/plain", env: { "action_dispatch.content_security_policy_nonce" => "n0nce" }

    assert_equal 3, response.body.scan('nonce="n0nce"').size
    assert_includes response.body, "q:[]"
    assert_equal response.body.bytesize.to_s, response.headers["Content-Length"]
  end
end
