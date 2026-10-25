# frozen_string_literal: true

require "json"

module PrivatusAnalytics
  # Turns page props (plan, role and so on) into JSON that is safe inside a <script>.
  # Keys follow the same rules as event props. Numbers, booleans and lists keep their JSON types.
  module PageProps
    MAX_ITEMS = 30
    UNSAFE = /[<>&\u2028\u2029]/

    module_function

    # A JSON object string, or nil when there are no props to send.
    def json(props)
      clean = Attributes.normalize(props).filter_map do |key, value|
        value = json_value(value)
        [key, value] unless value.nil?
      end
      return nil if clean.empty?

      JSON.generate(clean.to_h).gsub(UNSAFE) { |char| format("\\u%04x", char.ord) }
    end

    def json_value(value)
      return value.compact.first(MAX_ITEMS).filter_map { |item| scalar(item) } if value.is_a?(Array)

      scalar(value)
    end

    def scalar(value)
      case value
      when nil then nil
      when true, false, Integer then value
      when Float then value.finite? ? value : nil
      else value.to_s.scrub[0, Attributes::MAX_VALUE]
      end
    end
  end
end
