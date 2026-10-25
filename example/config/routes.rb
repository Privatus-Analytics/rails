# frozen_string_literal: true

# A page with a head and no tag, for the auto inject middleware.
AUTO_PAGE = lambda do |_env|
  html = <<~HTML
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>Auto inject</title>
    </head>
    <body><h1>Auto inject</h1><p>No tag in the template. The middleware adds it.</p></body>
    </html>
  HTML
  [200, { "content-type" => "text/html; charset=utf-8", "content-length" => html.bytesize.to_s }, [html]]
end

Rails.application.routes.draw do
  root "pages#home"
  get "/event", to: "pages#event"
  get "/nasty", to: "pages#nasty"
  get "/off", to: "pages#off"

  # Auto inject on this route only, so the other routes test the view helper alone.
  auto_config = PrivatusAnalytics.configuration.dup
  auto_config.auto_inject = true
  get "/auto", to: PrivatusAnalytics::Middleware.new(AUTO_PAGE, auto_config)
end
