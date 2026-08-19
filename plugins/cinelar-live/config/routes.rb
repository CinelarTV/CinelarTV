# Plugin routes for CinelarTV Live
# API routes only respond to .json — HTML requests fall through to the SPA
namespace :live, module: "live", path: "community", constraints: { format: :json } do
  get "status", to: "live_status#active_sessions"

  resources :events, only: [:index, :show, :create] do
    member do
      post :attend
      delete :unattend
    end

    resources :chat, only: [:index, :create] do
      member do
        delete :destroy, path: ""
      end
    end

    resource :reactions, only: [:create]
  end
end
