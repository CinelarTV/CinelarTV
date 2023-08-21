# frozen_string_literal: true

namespace :admin do
    get "dashboard" => "dashboard#index"
    resources :site_settings, only: [:create, :index]
    get "updates" => "updates#index"
    post "upgrade" => "updates#run_update"
    get "updates/progress" => "updates#check_progress"


    # Content Management related routes
    get '/contents/recommended-metadata', to: 'contents#find_recommended_metadata'

    # User Management related routes
    get '/users', to: 'users#index'
  
    
  end