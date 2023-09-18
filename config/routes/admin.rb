# frozen_string_literal: true

namespace :admin do
  get "dashboard" => "dashboard#index"
  get "dashboard/statistics" => "dashboard#reports"

  get "site_settings" => "site_settings#index"
  post "site_settings" => "site_settings#update"
  get "site_settings/:category" => "site_settings#index"
  get "updates" => "updates#index"
  post "upgrade" => "updates#run_update"
  get "updates/progress" => "updates#check_progress"
  post "restart" => "updates#restart_server"

  get "webhooks/logs" => "dashboard#webhook_logs"

  # Content Management related routes
  get "/content-manager/all", to: "contents#index"
  get "/content-manager/:id", to: "contents#show"
  get "/content-manager/:id/analytics", to: "contents#analytics"
  put "/content-manager/:id", to: "contents#update"
  get "/contents/recommended-metadata", to: "contents#find_recommended_metadata"
  post "/contents", to: "contents#create"
  delete "/content-manager/:id", to: "contents#destroy"
  post "/content-manager/:content_id/seasons", to: "contents#create_season"
  put "/content-manager/:id/reorder-seasons", to: "contents#reorder_seasons"
  get "/content-manager/:id/seasons/:season_id/episodes", to: "contents#episode_list"
  post "/content-manager/:id/seasons/:season_id/episodes", to: "contents#create_episode"
  put "/content-manager/:id/seasons/:season_id/reorder-episodes", to: "contents#reorder_episodes"

  # User Management related routes
  get "/users", to: "users#index"

  # Custom Pages related routes
  get "/custom-pages", to: "custom_pages#index"
end
