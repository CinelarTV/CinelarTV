# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root to: "application#index", as: "app"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  get "manifest.webmanifest" => "metadata#webmanifest", as: :manifest

  get "explore" => "home#homepage", as: :explore

  get '/user/profiles', to: 'session#profiles'
  # Routes that don't need a controller, can fallback to the application controller
  get 'profiles/select', to: 'application#index'


  post '/user/create-profile', to: 'profiles#create'
  post '/user/select-profile', to: 'session#select_profile'
  post '/user/deassign-profile', to: 'session#deassign_profile'
  delete '/user/profiles/:id', to: 'profiles#destroy'

  get '/user/default-avatars', to: 'profiles#default_avatars'

  get '/search', to: 'contents#search'


  # Dev route to refresh the settings
  if Rails.env.development?
    get "/r", to: "application#refresh_settings"
  end

  draw :admin

  authenticated :user, ->(u) { u.has_role?(:admin) } do
    mount Logster::Web => "/logs"
  end

  # Catch all route, to render the app (vue-router will take care of the routing)
  get "*path", to: "application#index"

end
