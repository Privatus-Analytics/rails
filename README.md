# Privatus Analytics for Rails

Adds the cookieless [Privatus Analytics](https://privatusanalytics.com)
tracking script to your Rails app with a view helper, or with an optional Rack
middleware that puts it in the `<head>` for you.

Privatus Analytics counts visits, sources, pages and conversions without
cookies, local storage or fingerprinting, so analytics does not need a consent
banner by itself. Check with your own counsel for your country.

The gem only prints the browser script. It never sends events from your server
and sets no cookies. You need a Privatus Analytics account to see reports, and
there is a free plan. Sign up at https://privatusanalytics.com.

## Requirements

* Ruby 3.2 or later.
* Rails 6.1 to 8.x.
* A Privatus Analytics site id (it starts with `pa_`). You find it under
  Site settings, Tracking.

## Install

Add the gem to your `Gemfile`:

```ruby
gem "privatus-analytics-rails"
```

Then run `bundle install`. For the full setup guide and every tracker option,
see the [Privatus Analytics docs](https://privatusanalytics.com/docs).

Set your site id with an environment variable:

```sh
PRIVATUS_SITE_ID=pa_YOURSITEID
```

or in `config/environments/production.rb` (or `config/application.rb`):

```ruby
config.privatus_analytics.site_id = "pa_YOURSITEID"
```

## Add the tag

Put the helper in the `<head>` of your layout, for example
`app/views/layouts/application.html.erb`:

```erb
<head>
  <title>My app</title>
  <%= privatus_analytics_tag %>
</head>
```

In production it prints:

```html
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>
```

The tag prints nothing when there is no site id, and nothing outside the
production environment (see below). If your app uses a Content Security Policy
nonce, the helper adds it for you.

### Or let the gem add it

If you would rather not touch your layouts, switch on the middleware:

```ruby
config.privatus_analytics.auto_inject = true
```

It adds the tag just before `</head>` in uncompressed `text/html` responses with
status 200. It skips Ajax requests, pages without a `<head>`, and pages that
already have the tag. Responses that carry a `Content-Encoding` header are left
alone, so if you compress inside the Rack stack, add the middleware above
`Rack::Deflater` or use the helper instead.

## Configuration

Every setting is optional except the site id.

```ruby
# config/environments/production.rb
Rails.application.configure do
  config.privatus_analytics.site_id        = "pa_YOURSITEID"      # or ENV["PRIVATUS_SITE_ID"]
  config.privatus_analytics.script_host    = "https://privatusstats.com" # or ENV["PRIVATUS_SCRIPT_HOST"]
  config.privatus_analytics.modules        = %w[engage auto vitals clicks ask]
  config.privatus_analytics.excluded_paths = %w[/admin/* /preview/*]
  config.privatus_analytics.domains        = %w[example.com www.example.com]
  config.privatus_analytics.spa            = "auto"   # auto, history, hash or off
  config.privatus_analytics.manual         = false    # true turns off the automatic pageview
  config.privatus_analytics.auto_inject    = false
  config.privatus_analytics.enabled_environments = %w[production]
  config.privatus_analytics.extra_attributes = { "data-mask" => "/orders/*->/orders/:id" }
end
```

| Setting | Default | What it does |
|---|---|---|
| `site_id` | `ENV["PRIVATUS_SITE_ID"]` | The `data-site` attribute. Nothing prints without it |
| `script_host` | `https://privatusstats.com` | Where `/js/pa.js` is served. Change it only if you host your own copy |
| `modules` | tracker default (`engage`) | The `data-modules` attribute. Setting it replaces the default, so keep `engage` for time on page and scroll depth. `[]` loads none |
| `excluded_paths` | none | The `data-exclude` attribute. Path globs the tracker never counts |
| `domains` | all hosts | The `data-domains` attribute. Count only these hostnames |
| `spa` | `auto` | The `data-spa` attribute |
| `manual` | `false` | The `data-manual` attribute |
| `enabled_environments` | `["production"]` | Rails environments that get the tag |
| `enabled` | `nil` | `true` or `false` forces the tag on or off in every environment |
| `auto_inject` | `false` | Adds the tag with a Rack middleware |
| `extra_attributes` | `{}` | Any other `data-*` attribute |

Each tracker attribute is explained in the [script attributes
reference](https://privatusanalytics.com/docs/tracker/attributes), and the
modules in [Modules](https://privatusanalytics.com/docs/tracker/modules).

You can also override a setting for one page:

```erb
<%= privatus_analytics_tag(modules: %w[engage auto], excluded_paths: ["/preview/*"]) %>
```

### Development and test

Development, test and staging requests are not counted by default, so your own
clicking around never reaches your reports. To see the tag while you build, set
`config.privatus_analytics.enabled = true`. The tracker also ignores `localhost`
unless you pass `data-allow-local` or `data-debug` (see [Debug
mode](https://privatusanalytics.com/docs/tracker/debug)):

```ruby
config.privatus_analytics.extra_attributes = { "data-debug" => "true" }
```

### Leaving people out

Use `data-exclude` through `excluded_paths` for admin areas. To leave out
signed-in staff, render the helper conditionally:

```erb
<%= privatus_analytics_tag unless current_user&.admin? %>
```

## Track your own events

The gem only loads the tracker. Track custom events from the browser, as
described in the [JavaScript API
docs](https://privatusanalytics.com/docs/tracker/javascript-api):

```erb
<button data-privatus-event="Newsletter signup" data-privatus-prop-list="weekly">Subscribe</button>
```

## Privacy

The script sets no cookies and stores nothing in the browser. See the
[privacy documentation](https://privatusanalytics.com/docs/privacy) for what is
collected.

## Development

The tests run in Docker so your local Ruby does not matter:

```sh
./run-docker.sh
```

It runs the Minitest suite against a small dummy Rails app, RuboCop, and
`gem build`.

## Contributing

Bug reports and pull requests are welcome at
https://github.com/Privatus-Analytics/rails.

## License

MIT. See [LICENSE.txt](LICENSE.txt). Privatus Analytics is a product of Two
Phase LLC, Wyoming, USA.
