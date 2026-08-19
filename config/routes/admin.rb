# frozen_string_literal: true

namespace :admin do
  # Icon picker for admin UI
  get "icon-picker/search" => "icon_picker#search"

  get "dashboard" => "dashboard#index"
  get "dashboard/statistics" => "dashboard#reports"

  get "site_settings" => "site_settings#index"
  put "site_settings" => "site_settings#update"
  get "site_settings/:category" => "site_settings#index"
  post "site_settings/test_connection" => "site_settings#test_storage_connection"
  get "plugins" => "plugins#index"
  get "updates" => "updates#index"
  post "upgrade" => "updates#run_update"
  post "restart" => "updates#restart_server"

  get "webhooks/logs" => "dashboard#webhook_logs"

  get "subscriptions" => "subscriptions#index"
  get "subscriptions/stats" => "subscriptions#stats"
  get "subscriptions/logs" => "subscriptions#logs"
  post "subscriptions/webhooks/test" => "subscriptions#test_webhook"
  get "subscriptions/:id" => "subscriptions#show"
  post "subscriptions/:id/cancel" => "subscriptions#cancel"
  post "subscriptions/:id/sync" => "subscriptions#sync"
  post "subscriptions/:id/grant" => "subscriptions#grant"
  post "subscriptions/create_grant" => "subscriptions#create_grant"

  # Content Management related routes
  get "/content-manager/all", to: "contents#index"
  get "/content-manager/media-integrity", to: "dashboard#index" # Redirigir al dashboard#index para que Vue maneje la ruta
  get "/content-manager/categories", to: "dashboard#index" # Redirigir al dashboard#index para que Vue maneje la ruta
  get "/content-manager/:id", to: "contents#show"
  get "/content-manager/:id/analytics", to: "contents#analytics"
  put "/content-manager/:id", to: "contents#update"
  get "/contents/recommended-metadata", to: "contents#find_recommended_metadata"
  get "/contents/:id/seasons-tmdb", to: "contents#find_seasons_from_tmdb"
  post "/contents", to: "contents#create"
  delete "/content-manager/:id", to: "contents#destroy"
  post "/content-manager/:id/sync-categories", to: "contents#sync_categories_from_tmdb"
  post "/content-manager/:id/sync-cast", to: "contents#sync_cast_from_tmdb"
  post "/content-manager/:id/sync-logo", to: "contents#sync_logo_from_tmdb"
  delete "/content-manager/:id/cast-members/:cast_member_id", to: "contents#remove_cast_member"
  post "/content-manager/:id/seasons", to: "contents#create_season"
  put "/content-manager/:id/seasons/:season_id", to: "contents#update_season"
  delete "/content-manager/:id/seasons/:season_id", to: "contents#delete_season"
  put "/content-manager/:id/reorder-seasons", to: "contents#reorder_seasons"
  get "/content-manager/:id/seasons/:season_id/episodes", to: "contents#episode_list"
  post "/content-manager/:id/seasons/:season_id/episodes", to: "contents#create_episode"
  get "/content-manager/:id/seasons/:season_id/episodes-tmdb", to: "contents#find_episodes_from_tmdb"
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
  post "/video_sources/:id/check", to: "video_sources#check", defaults: { format: 'json' }
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
  post "/email-templates/:key/preview" => "email_templates#preview", defaults: { format: 'json' }
  post "/email-templates/:key/test_send" => "email_templates#test_send", defaults: { format: 'json' }
  put "/email-templates/:key" => "email_templates#update", defaults: { format: 'json' }
  delete "/email-templates/:key" => "email_templates#destroy", defaults: { format: 'json' }

  # Email Style (outer template + CSS) routes
  get "/customize/email-style" => "dashboard#index", constraints: ->(req) { req.format.html? }
  get "/customize/email-style" => "email_styles#show", defaults: { format: 'json' }
  put "/customize/email-style" => "email_styles#update", defaults: { format: 'json' }

  # Backup Management routes
  get "/backups" => "dashboard#index", constraints: ->(req) { req.format.html? }
  get "/backups" => "backups#index", defaults: { format: 'json' }
  post "/backups" => "backups#create", defaults: { format: 'json' }
  get "/backups/sync" => "backups#sync", defaults: { format: 'json' }
  get "/backups/encryption_check" => "backups#encryption_check", defaults: { format: 'json' }
  post "/backups/cleanup" => "backups#cleanup", defaults: { format: 'json' }
  get "/backups/:id" => "dashboard#index", constraints: ->(req) { req.format.html? }
  get "/backups/:id" => "backups#show", defaults: { format: 'json' }
  get "/backups/:id/download" => "backups#download"
  post "/backups/:id/verify" => "backups#verify", defaults: { format: 'json' }
  get "/backups/:id/summary" => "backups#summary", defaults: { format: 'json' }
  post "/backups/:id/restore" => "backups#restore", defaults: { format: 'json' }
  delete "/backups/:id" => "backups#destroy", defaults: { format: 'json' }
end
