# frozen_string_literal: true

module PrivatusAnalytics
  # Settings for the tracking script. Set them with
  # `config.privatus_analytics.<name> = value` in a Rails environment file,
  # or with `PrivatusAnalytics.configure`.
  class Configuration
    DEFAULT_HOST = "https://privatusstats.com"
    MODULES = %w[engage auto vitals clicks ask].freeze
    SPA_MODES = %w[auto history hash off].freeze

    # The site id (starts with pa_). Falls back to ENV["PRIVATUS_SITE_ID"].
    attr_writer :site_id
    # Origin that serves /js/pa.js. Falls back to ENV["PRIVATUS_SCRIPT_HOST"].
    attr_writer :script_host
    # Tracker modules to load, for example %w[engage auto]. nil keeps the tracker default.
    attr_accessor :modules
    # Path globs the tracker never counts, for example %w[/admin/* /preview/*].
    attr_accessor :excluded_paths
    # Hostnames to count. nil counts every host.
    attr_accessor :domains
    # One of auto, history, hash, off. nil keeps the tracker default.
    attr_accessor :spa
    # true turns off the automatic pageview. See the manual mode docs.
    attr_accessor :manual
    # Rails environments that get the tag. Used when `enabled` is nil.
    attr_accessor :enabled_environments
    # true or false forces the tag on or off whatever the environment. nil uses enabled_environments.
    attr_accessor :enabled
    # true adds the tag to the head of HTML responses with a Rack middleware.
    attr_accessor :auto_inject
    # Extra data- attributes as a hash, for example { "data-mask" => "/orders/*->/orders/:id" }.
    attr_accessor :extra_attributes

    def initialize
      @site_id = nil
      @script_host = nil
      @modules = nil
      @excluded_paths = []
      @domains = nil
      @spa = nil
      @manual = false
      @enabled_environments = %w[production]
      @enabled = nil
      @auto_inject = false
      @extra_attributes = {}
    end

    def site_id
      value = @site_id.to_s.strip
      value = ENV.fetch("PRIVATUS_SITE_ID", "").strip if value.empty?
      value.empty? ? nil : value
    end

    def script_host
      value = @script_host.to_s.strip
      value = ENV.fetch("PRIVATUS_SCRIPT_HOST", "").strip if value.empty?
      value = DEFAULT_HOST if value.empty?
      value.chomp("/")
    end

    # Whether the current Rails environment should get the tag.
    def enabled?(environment = current_environment)
      return @enabled ? true : false unless @enabled.nil?

      Array(enabled_environments).map(&:to_s).include?(environment.to_s)
    end

    private

    def current_environment
      defined?(Rails) && Rails.respond_to?(:env) ? Rails.env.to_s : ENV.fetch("RAILS_ENV", "development")
    end
  end
end
