# frozen_string_literal: true

Rails.application.routes.draw do
  root "pages#home"
  get "plain", to: "pages#plain"
  get "data", to: "pages#data"
  get "bare", to: "pages#bare"
end
