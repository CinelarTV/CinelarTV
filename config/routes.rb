# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root to: "application#index", as: "app"

  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  get '/user/profiles', to: 'session#profiles'

  # Dev route to refresh the settings
  if Rails.env.development?
    get "/r", to: "application#refresh_settings"
  end

end
