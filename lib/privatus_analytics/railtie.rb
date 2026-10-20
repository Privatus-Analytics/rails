# frozen_string_literal: true

require "rails/railtie"

module PrivatusAnalytics
  # Wires the settings, the view helper and the optional middleware into Rails.
  class Railtie < Rails::Railtie
    config.privatus_analytics = PrivatusAnalytics.configuration

    initializer "privatus_analytics.helper" do
      ActiveSupport.on_load(:action_view) { include PrivatusAnalytics::Helper }
    end

    initializer "privatus_analytics.middleware" do |app|
      app.middleware.use PrivatusAnalytics::Middleware
    end
  end
end
