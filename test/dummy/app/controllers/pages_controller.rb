# frozen_string_literal: true

class PagesController < ActionController::Base
  layout "application", only: :home

  def home; end

  def plain
    render html: "<html><head><title>Plain</title></head><body>Hi</body></html>".html_safe, layout: false
  end

  def bare
    render html: "<p>No head here</p>".html_safe, layout: false
  end

  def data
    render json: { ok: true }
  end
end
