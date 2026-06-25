# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root to: "application#index", as: "app"

  devise_for :users, { controllers: { registrations: "users/registrations", sessions: "users/sessions", confirmations: "users/confirmations" } }
  devise_scope :user do
    get "/login" => "users/sessions#new"
    get "/signup" => "users/registrations#new"
    post "/signup" => "users/registrations#create"
    post "/login" => "users/sessions#create"
    delete "/logout" => "users/sessions#destroy"
    post "/confirmation" => "users/confirmations#create"
    get "/confirmation" => "users/confirmations#show"
  end

  use_doorkeeper
  # Enable the Device Authorization Grant flow
  use_doorkeeper_device_authorization_grant 
  

  get "manifest.webmanifest" => "metadata#webmanifest", as: :manifest

  get "explore" => "home#homepage", as: :explore
  get "shuffle_recommendations" => "home#shuffle_recommendations"

  get "/user/profiles", to: "session#profiles"
  # Routes that don't need a controller, can fallback to the application controller
  get "profiles/select", to: "application#index"

  post "/user/create-profile", to: "profiles#create"
  patch "/user/profiles/:id", to: "profiles#update"
  post "/session/select-profile", to: "session#select_profile"
  post "/session/deassign-profile", to: "session#deassign_profile"
  delete "/user/profiles/:id", to: "profiles#destroy"

  get "/session/current", to: "session#current_user_json"
  get "/session/csrf", to: "session#csrf"

  get "/user/default-avatars", to: "profiles#default_avatars"

  get "/search", to: "contents#search"

  post "/contents/:id/like", to: "likes#like"
  post "/contents/:id/unlike", to: "likes#unlike"
  post "/contents/:id/toggle_like", to: "likes#toggle_like"


  get "/contents/:id", to: "contents#show"
  get "/c/:id", to: redirect("/contents/%<id>s"), as: :content_short_url

  # Player routes
  get "/watch/:id", to: "player#watch"
  get "/watch/:id/:episode_id", to: "player#watch"
  put "/watch/:id/progress", to: "player#update_current_progress"

  post "/stream/ping", to: "stream_sessions#ping"
  post "/stream/end", to: "stream_sessions#end_stream"
  post "/stream/kill", to: "stream_sessions#kill"
  get "/stream/sessions", to: "stream_sessions#index"

  # Live TV routes
  get "/live_tv", to: "live_tv#index"
  get "/live_tv/:id", to: "live_tv#show"
  get "/live_tv/:id/guide", to: "live_tv#guide"
  get "/live/:id", to: "live_tv#watch", as: :watch_live
  get "/live_proxy", to: "live_proxy#stream"

  # Dev route to refresh the settings
  get "/r", to: "application#refresh_settings" if Rails.env.development?

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

  # Sitemap
  get "sitemap.xml" => "sitemap#index", format: "xml", as: :sitemap

  # Subscription provider webhooks

  post "subscriptions/webhooks/:provider" => "webhooks#subscription"

  # User Subscriptions

  get "account/billing" => "user_subscriptions#index"
  post "account/billing/subscribe" => "user_subscriptions#subscribe"
  post "account/billing/sync" => "user_subscriptions#sync"
  delete "account/billing/subscribe" => "user_subscriptions#destroy"
  post "account/billing/checkout" => "user_subscriptions#checkout"

  get "/404-content" => "exceptions#not_found_body"

  get "site" => "site#info"
  get "site/settings" => "site#settings"

  # API V1 Authentication Routes (for mobile/native clients)
  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      post "auth/refresh", to: "auth#refresh"
      get "auth/me", to: "auth#me"
      get "auth/profile-status", to: "auth#profile_status"
      post "auth/select-profile", to: "auth#select_profile"
      post "auth/deassign-profile", to: "auth#deassign_profile"
      post "auth/resend-confirmation", to: "auth#resend_confirmation"
      delete "auth/logout", to: "auth#logout"
    end
  end

  # =====================================================
  # Plugin Routes - Auto-discovered from plugins/
  # =====================================================
  # Register plugin autoload paths so controllers can be resolved
  # Must happen before routes are drawn
  Dir.glob(Rails.root.join("plugins", "*", "app", "controllers")).each do |plugin_controllers_dir|
    Rails.autoloaders.main.push_dir(plugin_controllers_dir)
  end
  Dir.glob(Rails.root.join("plugins", "*", "app", "models")).each do |plugin_models_dir|
    Rails.autoloaders.main.push_dir(plugin_models_dir)
  end

  # Load plugin routes
  #Dir.glob(Rails.root.join("plugins", "*", "config", "routes.rb")).each do |plugin_routes_file|
  #  instance_eval(File.read(plugin_routes_file))
  #end

  # Explicit 404 routes so the catch-all does not swallow them
  get "/404", to: "exceptions#not_found"
  get "/404.json", to: "exceptions#not_found_body"

  # This is the catch-all route for custom pages, but also for the Single Page Application (For now)
  # TODO: Create a route for each route in the SPA to avoid this catch-all
  get "*path", to: "custom_pages#show", as: :custom_page_catch_all, constraints: ->(req) { req.format.html? }
end
