# frozen_string_literal: true

require "rack/request"

module PrivatusAnalytics
  # Adds the script tag just before </head> in HTML responses.
  # Off unless `config.privatus_analytics.auto_inject = true`.
  class Middleware
    HEAD_CLOSE = %r{</head>}i
    MARKER = "/js/pa.js"
    NONCE_KEY = "action_dispatch.content_security_policy_nonce"

    def initialize(app, configuration = nil)
      @app = app
      @configuration = configuration
    end

    def call(env)
      status, headers, body = @app.call(env)
      return [status, headers, body] unless inject?(status, headers, env)

      inject(status, headers, body, env)
    end

    private

    def configuration
      @configuration || PrivatusAnalytics.configuration
    end

    def inject?(status, headers, env)
      return false unless configuration.auto_inject
      return false unless status == 200 && html?(headers) && !encoded?(headers)
      return false if env["HTTP_X_REQUESTED_WITH"].to_s.casecmp?("XMLHttpRequest")

      Tag.new(configuration).render?
    end

    # The Rails CSP nonce for this request, so the inline props and stub scripts are allowed.
    def nonce(env)
      return env[NONCE_KEY] if env[NONCE_KEY]
      return unless defined?(ActionDispatch::Request)

      ActionDispatch::Request.new(env).content_security_policy_nonce
    end

    def encoded?(headers)
      !(headers["content-encoding"] || headers["Content-Encoding"]).nil?
    end

    def html?(headers)
      type = headers["content-type"] || headers["Content-Type"]
      type.to_s.downcase.start_with?("text/html")
    end

    def inject(status, headers, body, env)
      html = +""
      body.each { |part| html << part.to_s }
      body.close if body.respond_to?(:close)

      unless html.include?(MARKER) || !html.match?(HEAD_CLOSE)
        tag = Tag.new(configuration, request: Rack::Request.new(env), nonce: nonce(env)).to_s
        html = html.sub(HEAD_CLOSE) { "#{tag}\n</head>" }
      end

      headers = headers.dup
      headers.delete("content-length")
      headers.delete("Content-Length")
      headers["content-length"] = html.bytesize.to_s
      [status, headers, [html]]
    end
  end
end
