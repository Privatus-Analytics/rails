# frozen_string_literal: true

require "test_helper"

class PagePropsTest < ActiveSupport::TestCase
  PageProps = PrivatusAnalytics::PageProps

  test "props become a JSON object" do
    assert_equal '{"plan":"pro","role":"admin"}', PageProps.json(plan: "pro", role: "admin")
  end

  test "empty props give nil" do
    assert_nil PageProps.json({})
    assert_nil PageProps.json(nil)
    assert_nil PageProps.json(gone: nil)
  end

  test "numbers, booleans and lists keep their JSON types" do
    assert_equal '{"seats":5,"ratio":1.5,"beta":true,"old":false,"flags":["a","b",3]}',
                 PageProps.json(seats: 5, ratio: 1.5, beta: true, old: false, flags: ["a", nil, "b", 3])
  end

  test "keys are cleaned like event props" do
    assert_equal '{"app_version":"2.1"}', PageProps.json("App Version" => "2.1")
  end

  test "limits props, list items and value length" do
    many = (1..40).to_h { |i| [:"p#{i}", i] }

    assert_equal 30, JSON.parse(PageProps.json(many)).size
    assert_equal 30, JSON.parse(PageProps.json(list: (1..50).map(&:to_s)))["list"].size
    assert_equal 500, JSON.parse(PageProps.json(long: "x" * 900))["long"].size
  end

  test "the JSON is safe inside a script tag" do
    json = PageProps.json(note: "</script><b>&\u2028\u2029")

    assert_equal '{"note":"\\u003c/script\\u003e\\u003cb\\u003e\\u0026\\u2028\\u2029"}', json
    refute_match(/[<>&\u2028\u2029]/, json)
  end
end
