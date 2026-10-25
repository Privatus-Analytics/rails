# frozen_string_literal: true

# The routes the conformance suite checks (see its CONTRACT.md).
class PagesController < ActionController::Base
  layout "application"

  PAGE_PROPS = { plan: "pro", role: "admin", beta: true, seats: 3 }.freeze
  NASTY = "</script><script>window.__pwned=1</script>\u2028\u2029&<>\"'"

  def home
    @page_props = PAGE_PROPS
  end

  def event
    @page_props = PAGE_PROPS
  end

  def nasty
    @page_props = PAGE_PROPS.merge(nasty: NASTY)
    @nasty = NASTY
  end

  # Off with the queue stub on: only the stub prints, so privatus.track still works.
  def off
    @page_props = PAGE_PROPS
    render layout: false
  end

  # Off with the queue stub off: nothing prints.
  def off_plain
    @page_props = PAGE_PROPS
    render layout: false
  end
end
