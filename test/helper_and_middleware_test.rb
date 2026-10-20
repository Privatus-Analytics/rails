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
end
