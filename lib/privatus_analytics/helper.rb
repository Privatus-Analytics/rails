# frozen_string_literal: true

module PrivatusAnalytics
  # View helpers. Included into ActionView by the Railtie.
  module Helper
    # Prints the Privatus Analytics script tag. Put it in the head of your layout.
    #
    #   <%= privatus_analytics_tag %>
    #   <%= privatus_analytics_tag(modules: %w[engage auto]) %>
    #   <%= privatus_analytics_tag(props: { plan: "pro" }, queue_stub: true) %>
    #
    # Prints nothing without a site id, or outside the enabled environments.
    # The one exception: with queue_stub on, the queue stub still prints (alone),
    # so privatus.track calls in your own JavaScript never fail in development.
    def privatus_analytics_tag(options = {})
      options = options.dup
      options[:nonce] ||= content_security_policy_nonce if respond_to?(:content_security_policy_nonce)
      options[:request] ||= request if respond_to?(:request)
      privatus_safe(Tag.new(PrivatusAnalytics.configuration, options).to_s)
    end

    # Data attributes for a custom event, as safe HTML to put inside a tag:
    #
    #   <button <%= privatus_event_attrs("Export CSV", format: "csv") %>>Export</button>
    #
    # On a <form> the event is sent when the form is submitted.
    def privatus_event_attrs(name, props = nil, **more_props)
      privatus_safe(Attributes.to_html(privatus_event_data(name, props, **more_props)))
    end

    # The same attributes as a hash with full attribute names, for the Rails tag helpers:
    #
    #   <%= tag.button "Export", **privatus_event_data("Export CSV", format: "csv"), class: "btn" %>
    #   <%= button_tag "Export", privatus_event_data("Export CSV") %>
    #   <%= form_with url: signup_path, html: privatus_event_data("Newsletter signup") do |f| %>
    #
    # Returns {} for an empty name.
    def privatus_event_data(name, props = nil, **more_props)
      Attributes.event(name, (props || {}).to_h.merge(more_props))
    end

    # The click map name attribute, as safe HTML: <a <%= privatus_click_attr("pricing.cta") %>>
    # Prints nothing when the name is not valid.
    def privatus_click_attr(name)
      privatus_safe(Attributes.to_html(privatus_click_data(name)))
    end

    # The click map name as a hash for the tag helpers:
    #
    #   <%= link_to "Pricing", pricing_path, **privatus_click_data("pricing.cta") %>
    def privatus_click_data(name)
      data = Attributes.click(name)
      privatus_warn_invalid_click(name) if data.empty?
      data
    end

    private

    def privatus_safe(html)
      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def privatus_warn_invalid_click(name)
      return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
      return if Rails.respond_to?(:env) && Rails.env.production?

      Rails.logger.warn("[privatus-analytics] click map name #{name.inspect} is not valid. Use letters, " \
                        "digits and _ . : - only, at most 100 characters. Nothing was printed.")
    end
  end
end
