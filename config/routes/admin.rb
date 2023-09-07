# frozen_string_literal: true

namespace :admin do
  get "dashboard" => "dashboard#index"
  resources :site_settings, only: [:create, :index]
  get "updates" => "updates#index"
  post "upgrade" => "updates#run_update"
  get "updates/progress" => "updates#check_progress"
  post "restart" => "updates#restart_server"

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

  # User Management related routes
  get "/users", to: "users#index"
end
