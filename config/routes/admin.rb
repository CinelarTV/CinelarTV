# frozen_string_literal: true

namespace :admin do
  get "dashboard" => "dashboard#index"
  get "dashboard/statistics" => "dashboard#reports"

  get "site_settings" => "site_settings#index"
  put "site_settings" => "site_settings#update"
  get "site_settings/:category" => "site_settings#index"
  get "updates" => "updates#index"
  post "upgrade" => "updates#run_update"
  get "updates/progress" => "updates#check_progress"
  post "restart" => "updates#restart_server"

  get "webhooks/logs" => "dashboard#webhook_logs"

  get "subscriptions" => "subscriptions#index"
  get "subscriptions/stats" => "subscriptions#stats"
  get "subscriptions/logs" => "subscriptions#logs"
  post "subscriptions/webhooks/test" => "subscriptions#test_webhook"
  get "subscriptions/plans" => "subscriptions#plans"
  post "subscriptions/plans" => "subscriptions#create_plan"
  put "subscriptions/plans/:plan_id" => "subscriptions#update_plan"
  post "subscriptions/plans/:plan_id/select" => "subscriptions#select_plan"
  post "subscriptions/plans/:plan_id/deactivate" => "subscriptions#deactivate_plan"
  get "subscriptions/:id" => "subscriptions#show"
  post "subscriptions/:id/cancel" => "subscriptions#cancel"
  post "subscriptions/:id/sync" => "subscriptions#sync"
  post "subscriptions/:id/grant" => "subscriptions#grant"

  # Content Management related routes
  get "/content-manager/all", to: "contents#index"
  get "/content-manager/media-integrity", to: "dashboard#index" # Redirigir al dashboard#index para que Vue maneje la ruta
  get "/content-manager/categories", to: "dashboard#index" # Redirigir al dashboard#index para que Vue maneje la ruta
  get "/content-manager/:id", to: "contents#show"
  get "/content-manager/:id/analytics", to: "contents#analytics"
  put "/content-manager/:id", to: "contents#update"
  get "/contents/recommended-metadata", to: "contents#find_recommended_metadata"
  post "/contents", to: "contents#create"
  delete "/content-manager/:id", to: "contents#destroy"
  post "/content-manager/:id/sync-categories", to: "contents#sync_categories_from_tmdb"
  post "/content-manager/:id/seasons", to: "contents#create_season"
  put "/content-manager/:id/reorder-seasons", to: "contents#reorder_seasons"
  get "/content-manager/:id/seasons/:season_id/episodes", to: "contents#episode_list"
  post "/content-manager/:id/seasons/:season_id/episodes", to: "contents#create_episode"
  put "/content-manager/:id/seasons/:season_id/reorder-episodes", to: "contents#reorder_episodes"
  delete "/content-manager/:id/seasons/:season_id/episodes/:episode_id", to: "contents#delete_episode"
  get "/content-manager/:id/seasons/:season_id/episodes/:episode_id/edit", to: "contents#edit_episode"
  put "/content-manager/:id/seasons/:season_id/episodes/:episode_id/edit", to: "contents#update_episode"

  # User Management related routes
  get "/users", to: "users#index"
  # Serve SPA for HTML requests to user detail; API JSON handled below
  get "/users/:id", to: "dashboard#index", constraints: ->(req) { req.format.html? }
  get "/users/:id", to: "users#show", defaults: { format: 'json' }
  post "/users/create_user", to: "users#create_user", defaults: { format: 'json' }
  post "/users/:id/suspend", to: "users#suspend", defaults: { format: 'json' }
  post "/users/:id/unsuspend", to: "users#unsuspend", defaults: { format: 'json' }
  post "/users/:id/deactivate", to: "users#deactivate", defaults: { format: 'json' }
  post "/users/:id/activate", to: "users#activate", defaults: { format: 'json' }
  #delete "/users/:id", to: "users#destroy", defaults: { format: 'json' }

  # Custom Pages related routes
  get "/custom-pages", to: "custom_pages#index"

  # Video Sources related routes
  # For listing and creating video sources associated with a content
  get "/contents/:content_id/video_sources", to: "video_sources#index"
  post "/contents/:content_id/video_sources", to: "video_sources#create"

  # For listing and creating video sources associated with an episode
  get "/episodes/:episode_id/video_sources", to: "video_sources#index"
  post "/episodes/:episode_id/video_sources", to: "video_sources#create"

  # For listing and creating segments associated with an episode
  get "/episodes/:episode_id/segments", to: "segments#index"
  post "/episodes/:episode_id/segments", to: "segments#create"
  put "/episodes/:episode_id/segments/:id", to: "segments#update"
  delete "/episodes/:episode_id/segments/:id", to: "segments#destroy"

  # For listing and creating segments associated with a content
  get "/contents/:content_id/segments", to: "segments#index"
  post "/contents/:content_id/segments", to: "segments#create"
  put "/contents/:content_id/segments/:id", to: "segments#update"
  delete "/contents/:content_id/segments/:id", to: "segments#destroy"

  # For updating and deleting a specific video source
  get "/video_sources/broken", to: "video_sources#broken", defaults: { format: 'json' }
  put "/video_sources/:id", to: "video_sources#update"
  delete "/video_sources/:id", to: "video_sources#destroy"

  # Live TV Management routes
  resources :live_tv_channels, only: [:index, :create, :update, :destroy] do
    collection do
      post :reorder
    end
  end

  resources :xmltv_sources, only: [:index, :create, :update, :destroy] do
    member do
      post :fetch
      get :channels
    end
  end

  # Categories Management routes
  get "/categories", to: "dashboard#index", constraints: ->(req) { req.format.html? }
  resources :categories, only: [:index, :create, :update, :destroy] do
    collection do
      post :populate_from_tmdb
    end
  end

  # Email Templates Management routes
  get "/email-templates" => "dashboard#index", constraints: ->(req) { req.format.html? }
  get "/email-templates" => "email_templates#index", defaults: { format: 'json' }
  get "/email-templates/:key" => "dashboard#index", constraints: ->(req) { req.format.html? }
  get "/email-templates/:key" => "email_templates#show", defaults: { format: 'json' }
  put "/email-templates/:key" => "email_templates#update", defaults: { format: 'json' }
  delete "/email-templates/:key" => "email_templates#destroy", defaults: { format: 'json' }
end
