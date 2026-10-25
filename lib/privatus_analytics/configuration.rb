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
    # Page props sent with every pageview and event, for example { plan: "pro", role: "admin" }.
    # A hash, or a lambda called on each request: ->(request) { { plan: Current.account&.plan } }.
    # Never put names, emails, user ids or anything else that points to one person here.
    attr_accessor :props
    # true prints the tracker's queue stub first, so privatus.track works before pa.js loads.
    attr_accessor :queue_stub

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
      @props = {}
      @queue_stub = false
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

    # The configured props for one request. Calls the lambda when props is one.
    # The request is an ActionDispatch::Request in views and a Rack::Request in the middleware.
    def page_props(request = nil)
      value = props
      if value.respond_to?(:call)
        value = value.respond_to?(:arity) && value.arity.zero? ? value.call : value.call(request)
      end
      value.respond_to?(:to_h) ? value.to_h : {}
    end

    private

    def current_environment
      defined?(Rails) && Rails.respond_to?(:env) ? Rails.env.to_s : ENV.fetch("RAILS_ENV", "development")
    end
  end
end
