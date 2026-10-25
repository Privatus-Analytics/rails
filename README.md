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
`Rack::Deflater` or use the helper instead. The middleware also adds the
Rails Content Security Policy nonce when your app has one.

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
  config.privatus_analytics.props          = ->(request) { { plan: Current.account&.plan } }
  config.privatus_analytics.queue_stub     = false
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
| `props` | `{}` | Page props sent with every pageview and event. A hash, or a lambda that gets the request. See below |
| `queue_stub` | `false` | Prints a small script first, so `privatus.track` calls made before the tracker loads are kept and sent later |

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

## Product analytics: see which features people use

Privatus can show which buttons, forms and features people really use. You
add a few attributes to your HTML. The tracker reads them in the browser and
sends the events. Your server still sends nothing.

### Name events well

Use a short "Noun verb" name, like `Report exported` or `Invite sent`. Put the
details in props, not in the name. So write `Report exported` with
`format: "csv"`, not `Report exported as CSV`. Then all exports add up in one
place, and you can split them by format.

### Events on buttons, links and forms

`privatus_event_attrs` prints the attributes inside a tag you write yourself:

```erb
<button <%= privatus_event_attrs("Report exported", format: "csv", source: "toolbar") %>>Export</button>
```

It prints:

```html
<button data-privatus-event="Report exported" data-privatus-prop-format="csv" data-privatus-prop-source="toolbar">Export</button>
```

With the Rails tag helpers, use `privatus_event_data`. It returns a hash with
the full attribute names, so you spread it into the options:

```erb
<%= tag.button "Export", **privatus_event_data("Report exported", format: "csv"), class: "btn" %>
<%= button_tag "Export", privatus_event_data("Report exported", format: "csv") %>
<%= link_to "Read the guide", guide_path, **privatus_event_data("Guide opened") %>
```

On a form, the event is sent when the form is submitted. `form_with` needs
the hash under `html:`:

```erb
<%= form_with url: newsletter_path, html: privatus_event_data("Newsletter joined", list: "weekly") do |f| %>
```

The rules:

* The name is trimmed and cut to 120 characters. An empty name prints nothing.
* Prop keys are made lowercase. Anything that is not a letter, a digit or `_`
  becomes `_`, so `"Report Type"` becomes `report_type`. Keys are cut to 64
  characters.
* At most 30 props. Values become text: `true`, `false`, numbers as written,
  lists joined with commas. `nil` values are left out. Values are cut to 500
  characters.
* Everything is escaped for HTML.
* The attributes print in every environment, even when the tag is off. They do
  nothing without the tracker, so your pages look the same in development and
  production.

### Click maps

A click map shows where people click on a page. Give the important parts a
name so they stay easy to find, even when the page changes:

```erb
<a href="/pricing" <%= privatus_click_attr("pricing.cta") %>>See plans</a>
<%= link_to "See plans", pricing_path, **privatus_click_data("pricing.cta") %>
```

A name may use letters, digits and `_ . : -`, up to 100 characters. Anything
else prints nothing, and in development the gem writes a warning to the Rails
log.

### Page props: plan, role and other groups

Page props are sent with every pageview and event on the page. Use them to
split your reports by plan, role, app version, feature flag or account tier.

Set them for every page with a lambda. It runs on each request and gets the
request:

```ruby
config.privatus_analytics.props = lambda do |request|
  { plan: Current.account&.plan, role: Current.user&.role, app_version: "2.4" }
end
```

A plain hash works too. You can also set or change props for one page. They
are merged over the configured ones, and `nil` removes one:

```erb
<%= privatus_analytics_tag(props: { section: "billing", role: nil }) %>
```

The tag then prints a small script before the tracker, with your Content
Security Policy nonce when you have one, and points the tracker at it:

```html
<script nonce="...">window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID" data-props="privatusPageProps"></script>
```

Keys follow the same rules as event props. Numbers and true or false stay as
they are, and lists stay lists (up to 30 items). The props are escaped so they
are safe inside a script. The middleware uses the same setting. There it calls
your lambda with a `Rack::Request`, so only use what both kinds of request
have, like `path`, `params`, `session` and `env`.

**Never put names, emails, user ids or anything that points to one person in
props.** Privatus counts visitors without any id. Put groups (like the plan or
the role), not people. The server also removes emails and long ids it finds.

### Track from your own JavaScript

For things that are not a click or a submit, call the tracker from your
JavaScript, as the [JavaScript API
docs](https://privatusanalytics.com/docs/tracker/javascript-api) explain:

```js
privatus.track("Feature used", { feature: "export" })
```

If your code may run before the tracker has loaded, switch on the queue stub.
It prints a tiny script before the tracker that keeps your calls in a list and
sends them once the tracker is ready:

```ruby
config.privatus_analytics.queue_stub = true
```

or for one layout: `<%= privatus_analytics_tag(queue_stub: true) %>`. Like the
tag, the stub prints only where the tag is on, so in development use
`window.privatus && privatus.track(...)`.

### See the results

* [Funnels](https://privatusanalytics.com/docs/features/funnels): how many
  people go from one step to the next.
* [Click maps](https://privatusanalytics.com/docs/features/click-maps): where
  people click.
* [Goals](https://privatusanalytics.com/docs/features/goals): turn an event
  into a goal to count conversions.
* [Events](https://privatusanalytics.com/docs/events): every custom event and
  its props.

## Privacy

The script sets no cookies and stores nothing in the browser. The event, click
and props helpers only print HTML attributes and a small script. Keep people
out of your props and event props: no names, emails or user ids. See the
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
