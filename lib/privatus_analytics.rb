# frozen_string_literal: true

require "privatus_analytics/version"
require "privatus_analytics/configuration"
require "privatus_analytics/attributes"
require "privatus_analytics/page_props"
require "privatus_analytics/tag"
require "privatus_analytics/middleware"
require "privatus_analytics/helper"
# Adds the cookieless Privatus Analytics tracking script to Rails apps.
#
# The gem only prints the browser script. It never sends events from the server.
module PrivatusAnalytics
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    # Puts every setting back to its default. Handy in tests.
    def reset_configuration!
      configuration.send(:initialize)
    end
  end
end

require "privatus_analytics/railtie" if defined?(Rails::Railtie)
