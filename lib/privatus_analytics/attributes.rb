# frozen_string_literal: true

require "cgi"

module PrivatusAnalytics
  # Builds the data attributes the tracker reads for custom events and click maps.
  # Plain Ruby, no Rails needed. The view helpers wrap these methods.
  module Attributes
    MAX_NAME = 120
    MAX_KEY = 64
    MAX_PROPS = 30
    MAX_VALUE = 500
    CLICK_NAME = /\A[A-Za-z0-9_.:-]{1,100}\z/

    module_function

    # { "data-privatus-event" => name, "data-privatus-prop-<key>" => value, ... }, or {} for an empty name.
    def event(name, props = {})
      name = name.to_s.strip[0, MAX_NAME].to_s.strip
      return {} if name.empty?

      attrs = { "data-privatus-event" => name }
      normalize(props).each { |key, value| attrs["data-privatus-prop-#{key}"] = string_value(value) }
      attrs
    end

    # { "data-privatus-click" => name }, or {} when the name is not valid.
    def click(name)
      name.to_s.match?(CLICK_NAME) ? { "data-privatus-click" => name.to_s } : {}
    end

    # Whether a click map name is valid: letters, digits, _ . : - and at most 100 characters.
    def valid_click?(name)
      name.to_s.match?(CLICK_NAME)
    end

    # Turns an attribute hash into HTML, with every value escaped.
    def to_html(attrs)
      attrs.map { |name, value| %(#{name}="#{CGI.escapeHTML(value.to_s)}") }.join(" ")
    end

    # Lowercases keys, swaps anything outside a-z 0-9 _ for _, cuts them to 64 characters,
    # drops nil values and keeps the first 30 props.
    def normalize(props)
      clean = {}
      (props || {}).to_h.each do |key, value|
        key = normalize_key(key)
        clean[key] = value unless key.empty? || value.nil?
      end
      clean.first(MAX_PROPS).to_h
    end

    def normalize_key(key)
      key.to_s.downcase.gsub(/[^a-z0-9_]/, "_")[0, MAX_KEY]
    end

    def string_value(value)
      text = value.is_a?(Array) ? value.compact.join(",") : value.to_s
      text[0, MAX_VALUE]
    end
  end
end
