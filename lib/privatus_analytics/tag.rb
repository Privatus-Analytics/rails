# frozen_string_literal: true

require "cgi"

module PrivatusAnalytics
  # Builds the script tag. Returns an empty string when no tag should print.
  class Tag
    LIST_OPTIONS = { modules: "data-modules", excluded_paths: "data-exclude", domains: "data-domains" }.freeze

    def initialize(configuration = PrivatusAnalytics.configuration, overrides = {})
      @configuration = configuration
      @overrides = overrides.transform_keys(&:to_sym)
    end

    def render?
      !@configuration.site_id.nil? && @configuration.enabled?
    end

    def to_s
      return "" unless render?

      parts = attributes.map { |name, value| value == true ? name : %(#{name}="#{CGI.escapeHTML(value.to_s)}") }
      "<script #{parts.join(' ')}></script>"
    end

    def attributes
      attrs = { "defer" => true, "src" => "#{@configuration.script_host}/js/pa.js",
                "data-site" => @configuration.site_id }
      add_options(attrs)
      @configuration.extra_attributes.each { |name, value| attrs[name.to_s] = value unless value.nil? }
      attrs["nonce"] = @overrides[:nonce] if @overrides[:nonce]
      attrs
    end

    private

    def add_options(attrs)
      LIST_OPTIONS.each do |name, attribute|
        values = list(option(name))
        # nil keeps the tracker default. An empty modules list loads none.
        attrs[attribute] = values.join(",") if values && (name == :modules || !values.empty?)
      end
      spa = option(:spa).to_s
      attrs["data-spa"] = spa if Configuration::SPA_MODES.include?(spa) && spa != "auto"
      attrs["data-manual"] = "true" if option(:manual) == true
    end

    def option(name)
      @overrides.key?(name) ? @overrides[name] : @configuration.public_send(name)
    end

    # nil stays nil. Anything else becomes a clean array of strings.
    def list(value)
      return nil if value.nil?

      Array(value).flat_map { |item| item.to_s.split(",") }.map(&:strip).reject(&:empty?)
    end
  end
end
