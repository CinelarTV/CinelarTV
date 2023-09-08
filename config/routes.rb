# frozen_string_literal: true

require "sidekiq/web"
require "mini_scheduler/web"

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root to: "application#index", as: "app"

  devise_for :users, controllers: {
                       sessions: "users/sessions",
                       registrations: "users/registrations",
                     }

  get "manifest.webmanifest" => "metadata#webmanifest", as: :manifest

  get "explore" => "home#homepage", as: :explore

  get "/user/profiles", to: "session#profiles"
  # Routes that don't need a controller, can fallback to the application controller
  get "profiles/select", to: "application#index"

  post "/user/create-profile", to: "profiles#create"
  post "/user/select-profile", to: "session#select_profile"
  post "/user/deassign-profile", to: "session#deassign_profile"
  delete "/user/profiles/:id", to: "profiles#destroy"

  get "/user/current", to: "session#current_user_json"
  get "/session/csrf", to: "session#csrf"

  get "/user/default-avatars", to: "profiles#default_avatars"

  get "/search", to: "contents#search"

  post "/contents/:id/like", to: "likes#like"
  post "/contents/:id/unlike", to: "likes#unlike"

  get "/contents/:id", to: "contents#show"
  get "/t/:id", to: redirect("/contents/%{id}")

  # Player routes
  get "/watch/:id", to: "player#watch"
  put "/watch/:id/progress", to: "player#update_current_progress"

  # Dev route to refresh the settings
  if Rails.env.development?
    get "/r", to: "application#refresh_settings"
  end

  draw :admin

  authenticated :user, ->(u) { u.has_role?(:admin) } do
    mount Logster::Web => "/logs"
    mount Sidekiq::Web => "/sidekiq"
  end

  # Wizard

  get "wizard" => "wizard#index"
  get "wizard/steps/:id" => "wizard#index"
  put "wizard/steps/:id" => "steps#update"

  # Finish Installation

  get "finish-installation" => "finish_installation#index"
  get "finish-installation/create-account" => "finish_installation#create_account"
  post "finish-installation/create-account" => "finish_installation#create_account"

  get "capybara" => "application#capybara_spin"

  # Catch all route, to render the app (vue-router will take care of the routing)
  get "*path", to: "application#index"
end
