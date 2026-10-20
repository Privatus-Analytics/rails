# frozen_string_literal: true

module PrivatusAnalytics
  # View helper. Included into ActionView by the Railtie.
  module Helper
    # Prints the Privatus Analytics script tag. Put it in the head of your layout.
    #
    #   <%= privatus_analytics_tag %>
    #   <%= privatus_analytics_tag(modules: %w[engage auto]) %>
    #
    # Prints nothing without a site id, or outside the enabled environments.
    def privatus_analytics_tag(options = {})
      options = options.dup
      options[:nonce] ||= content_security_policy_nonce if respond_to?(:content_security_policy_nonce)
      html = Tag.new(PrivatusAnalytics.configuration, options).to_s
      html.respond_to?(:html_safe) ? html.html_safe : html
    end
  end
end
