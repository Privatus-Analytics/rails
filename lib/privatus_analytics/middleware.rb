# frozen_string_literal: true

module PrivatusAnalytics
  # Adds the script tag just before </head> in HTML responses.
  # Off unless `config.privatus_analytics.auto_inject = true`.
  class Middleware
    HEAD_CLOSE = %r{</head>}i
    MARKER = "/js/pa.js"

    def initialize(app, configuration = nil)
      @app = app
      @configuration = configuration
    end

    def call(env)
      status, headers, body = @app.call(env)
      return [status, headers, body] unless inject?(status, headers, env)

      inject(status, headers, body)
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

    def encoded?(headers)
      !(headers["content-encoding"] || headers["Content-Encoding"]).nil?
    end

    def html?(headers)
      type = headers["content-type"] || headers["Content-Type"]
      type.to_s.downcase.start_with?("text/html")
    end

    def inject(status, headers, body)
      html = +""
      body.each { |part| html << part.to_s }
      body.close if body.respond_to?(:close)

      unless html.include?(MARKER) || !html.match?(HEAD_CLOSE)
        tag = Tag.new(configuration).to_s
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
