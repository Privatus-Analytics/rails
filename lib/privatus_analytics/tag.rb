# frozen_string_literal: true

require "cgi"

module PrivatusAnalytics
  # Builds the script tag. Returns an empty string when no tag should print.
  #
  # Before the tracker tag it can also print the queue stub (queue_stub) and the
  # page props script (props), each with the CSP nonce when there is one.
  class Tag
    LIST_OPTIONS = { modules: "data-modules", excluded_paths: "data-exclude", domains: "data-domains" }.freeze
    PROPS_FUNCTION = "privatusPageProps"
    QUEUE_STUB = "window.privatus=window.privatus||{q:[]};['track','pageview','props','optOut','optIn','ready']" \
                 ".forEach(function(m){window.privatus[m]=window.privatus[m]||function(){window.privatus.q.push(" \
                 "[m,Array.prototype.slice.call(arguments)])}})"

    # overrides: any setting (site_id, script_host, enabled and the rest), plus nonce:,
    # request: (passed to a props lambda) and props: (merged over the configured props;
    # a nil value removes one).
    def initialize(configuration = PrivatusAnalytics.configuration, overrides = {})
      @configuration = configuration
      @overrides = overrides.transform_keys(&:to_sym)
    end

    def render?
      !site_id.nil? && enabled?
    end

    def to_s
      return "" unless render?

      props_json = PageProps.json(page_props)
      html = []
      html << inline_script(QUEUE_STUB) if option(:queue_stub) == true
      html << inline_script("window.#{PROPS_FUNCTION}=function(){return #{props_json}}") if props_json
      html << script_tag(props_json ? { "data-props" => PROPS_FUNCTION } : {})
      html.join("\n")
    end

    def attributes
      attrs = { "defer" => true, "src" => "#{script_host}/js/pa.js", "data-site" => site_id }
      add_options(attrs)
      (option(:extra_attributes) || {}).each { |name, value| attrs[name.to_s] = value unless value.nil? }
      attrs["nonce"] = @overrides[:nonce] if @overrides[:nonce]
      attrs
    end

    # Configured props for this request with the per call props merged on top.
    def page_props
      props = keyed(@configuration.page_props(@overrides[:request]))
      props.merge(keyed(@overrides[:props]))
    end

    private

    # A per call site_id, script_host or enabled wins over the configuration.
    def site_id
      value = @overrides[:site_id].to_s.strip
      value.empty? ? @configuration.site_id : value
    end

    def script_host
      value = @overrides[:script_host].to_s.strip
      value.empty? ? @configuration.script_host : value.chomp("/")
    end

    def enabled?
      return @overrides[:enabled] ? true : false unless @overrides[:enabled].nil?

      @configuration.enabled?
    end

    def script_tag(more)
      parts = attributes.merge(more).map do |name, value|
        value == true ? name : %(#{name}="#{CGI.escapeHTML(value.to_s)}")
      end
      "<script #{parts.join(' ')}></script>"
    end

    def inline_script(code)
      nonce = @overrides[:nonce]
      opening = nonce ? %(<script nonce="#{CGI.escapeHTML(nonce.to_s)}">) : "<script>"
      "#{opening}#{code}</script>"
    end

    def keyed(props)
      (props || {}).to_h.transform_keys { |key| Attributes.normalize_key(key) }
    end

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
