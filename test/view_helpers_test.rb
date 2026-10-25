# frozen_string_literal: true

require "test_helper"

class ViewHelpersTest < ActionView::TestCase
  include PrivatusAnalytics::Helper

  test "privatus_event_attrs prints safe data attributes" do
    html = privatus_event_attrs("Export CSV", format: "csv", source: "toolbar")

    assert_predicate html, :html_safe?
    assert_equal 'data-privatus-event="Export CSV" data-privatus-prop-format="csv" ' \
                 'data-privatus-prop-source="toolbar"', html
  end

  test "privatus_event_attrs also takes a props hash" do
    assert_equal 'data-privatus-event="Saved" data-privatus-prop-report_type="weekly"',
                 privatus_event_attrs("Saved", { "Report Type" => "weekly" })
  end

  test "privatus_event_attrs escapes and prints nothing for an empty name" do
    assert_equal 'data-privatus-event="&lt;b&gt;"', privatus_event_attrs("<b>")
    assert_equal "", privatus_event_attrs(" ")
    assert_predicate privatus_event_attrs(" "), :html_safe?
  end

  test "event attributes print even when the tag is off" do
    PrivatusAnalytics.configuration.enabled = false

    assert_includes privatus_event_attrs("Export CSV"), "data-privatus-event"
  end

  test "privatus_event_data works with tag helpers" do
    html = tag.button("Export", **privatus_event_data("Export CSV", format: "csv"), class: "btn")

    assert_dom_equal '<button data-privatus-event="Export CSV" data-privatus-prop-format="csv" class="btn">' \
                     "Export</button>", html
  end

  test "privatus_event_data works with button_tag and link_to" do
    assert_dom_equal '<button name="button" type="submit" data-privatus-event="Export CSV">Export</button>',
                     button_tag("Export", privatus_event_data("Export CSV"))
    assert_dom_equal '<a data-privatus-event="Docs opened" href="/docs">Docs</a>',
                     link_to("Docs", "/docs", **privatus_event_data("Docs opened"))
  end

  test "privatus_event_data works on a form with form_with html" do
    html = form_with(url: "/signup", html: privatus_event_data("Newsletter signup", list: "weekly")) { "" }

    assert_includes html, 'data-privatus-event="Newsletter signup"'
    assert_includes html, 'data-privatus-prop-list="weekly"'
  end

  test "privatus_event_data escapes through the tag helper" do
    html = tag.button("Go", **privatus_event_data(%(Say "hi")))

    assert_includes html, 'data-privatus-event="Say &quot;hi&quot;"'
  end

  test "privatus_click_attr and privatus_click_data" do
    assert_equal 'data-privatus-click="pricing.cta"', privatus_click_attr("pricing.cta")
    assert_predicate privatus_click_attr("pricing.cta"), :html_safe?
    assert_dom_equal '<a data-privatus-click="pricing.cta" href="/pricing">Pricing</a>',
                     link_to("Pricing", "/pricing", **privatus_click_data("pricing.cta"))
  end

  test "an invalid click name prints nothing" do
    assert_equal "", privatus_click_attr("not valid!")
    assert_empty privatus_click_data("not valid!")
  end

  test "event and click data can be combined" do
    html = tag.button("Buy", **privatus_event_data("Plan chosen", plan: "pro"), **privatus_click_data("pricing.buy"))

    assert_includes html, 'data-privatus-click="pricing.buy"'
    assert_includes html, 'data-privatus-prop-plan="pro"'
  end
end

class ViewHelpersTagTest < ActionView::TestCase
  include PrivatusAnalytics::Helper

  setup do
    PrivatusAnalytics.configuration.site_id = "pa_TEST123456"
    PrivatusAnalytics.configuration.enabled = true
  end

  def content_security_policy_nonce
    "n0nce"
  end

  test "the tag passes the view request to the props lambda" do
    PrivatusAnalytics.configuration.props = ->(request) { { path: request.path } }
    request.path = "/reports"

    assert_includes privatus_analytics_tag, '{"path":"/reports"}'
  end

  test "props and queue stub scripts get the CSP nonce" do
    html = privatus_analytics_tag(props: { plan: "pro" }, queue_stub: true)

    assert_predicate html, :html_safe?
    assert_equal 3, html.scan('nonce="n0nce"').size
    assert_includes html, 'data-props="privatusPageProps"'
  end
end
