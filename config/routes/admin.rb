# frozen_string_literal: true

namespace :admin do
    get "dashboard" => "dashboard#index"
    resources :site_settings, only: [:create, :index]
    get "updates" => "updates#index"
    post "upgrade" => "updates#run_update"
    get "updates/progress" => "updates#check_progress"


    # Content Management related routes
    get '/content-manager/all', to: 'contents#index'
    get '/content-manager/:id', to: 'contents#show'
    get '/contents/recommended-metadata', to: 'contents#find_recommended_metadata'
    post '/contents', to: 'contents#create'

    # User Management related routes
    get '/users', to: 'users#index'
  
    
  end