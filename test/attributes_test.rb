# frozen_string_literal: true

require "test_helper"

class AttributesTest < ActiveSupport::TestCase
  Attributes = PrivatusAnalytics::Attributes

  test "an event becomes data attributes" do
    assert_equal({ "data-privatus-event" => "Export CSV", "data-privatus-prop-format" => "csv",
                   "data-privatus-prop-source" => "toolbar" },
                 Attributes.event("Export CSV", format: "csv", source: "toolbar"))
  end

  test "the event name is trimmed and cut to 120 characters" do
    assert_equal "Export CSV", Attributes.event("  Export CSV  ")["data-privatus-event"]
    assert_equal "a" * 120, Attributes.event("a" * 200)["data-privatus-event"]
  end

  test "an empty event name gives nothing" do
    assert_empty Attributes.event("   ", format: "csv")
    assert_empty Attributes.event(nil)
  end

  test "prop keys are lowercased, cleaned and cut to 64 characters" do
    attrs = Attributes.event("Saved", "Report Type" => "a", "x-y" => "b", ("K" * 80) => "c")

    assert_equal "a", attrs["data-privatus-prop-report_type"]
    assert_equal "b", attrs["data-privatus-prop-x_y"]
    assert_equal "c", attrs["data-privatus-prop-#{'k' * 64}"]
  end

  test "values become strings and nil values are dropped" do
    attrs = Attributes.event("Saved", on: true, off: false, count: 3, ratio: 1.5, tags: %w[a b], gone: nil)

    names = %w[on off count ratio tags].map { |key| "data-privatus-prop-#{key}" }

    assert_equal %w[true false 3 1.5 a,b], attrs.values_at(*names)
    refute attrs.key?("data-privatus-prop-gone")
  end

  test "values are cut to 500 characters and at most 30 props are kept" do
    props = (1..40).to_h { |i| [:"p#{i}", "v"] }

    assert_equal 31, Attributes.event("Saved", props).size
    assert_equal 500, Attributes.event("Saved", long: "x" * 900)["data-privatus-prop-long"].size
  end

  test "html escapes every value" do
    html = Attributes.to_html(Attributes.event(%(Say "hi" <now>), note: "a&b"))

    assert_equal 'data-privatus-event="Say &quot;hi&quot; &lt;now&gt;" data-privatus-prop-note="a&amp;b"', html
  end

  test "a valid click name becomes a data attribute" do
    assert_equal({ "data-privatus-click" => "pricing.cta" }, Attributes.click("pricing.cta"))
    assert_equal({ "data-privatus-click" => "a-b_c:d.1" }, Attributes.click("a-b_c:d.1"))
  end

  test "an invalid click name gives nothing" do
    ["", "has space", "x" * 101, "<b>", nil].each { |name| assert_empty Attributes.click(name) }
  end
end
