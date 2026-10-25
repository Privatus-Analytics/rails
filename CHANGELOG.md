# Changelog

## 1.1.0 - 2026-10-25

- `privatus_event_attrs` and `privatus_event_data` for custom events on buttons, links and forms.
- `privatus_click_attr` and `privatus_click_data` for click map names.
- Page props: `config.privatus_analytics.props` (a hash, or a lambda that gets the request) and
  `privatus_analytics_tag(props: ...)`. They print the `privatusPageProps` script and `data-props`.
- `queue_stub` setting, so `privatus.track` calls made before the tracker loads are kept.
- The middleware now passes your props lambda a `Rack::Request` and adds the Rails CSP nonce when there is one.
- `run-docker.sh` now stops at the first failing step.

## 1.0.0 - 2026-10-20

- Initial release.
- `privatus_analytics_tag` view helper.
- Optional Rack middleware that adds the tag to the head of HTML responses (off by default).
- Settings for site id, script host, modules, excluded paths, single-page app mode and more.
- Skips every environment except production by default.
