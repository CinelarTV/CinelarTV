# Plugin routes for WatchParty
# These routes are auto-mounted by config/routes.rb
# The namespace resolves to WatchParty::SessionsController
namespace :watch_party, module: "watch_party", path: "watch_party" do
  post "sessions", to: "sessions#create"
  post "sessions/:session_id/join", to: "sessions#join"
  post "sessions/:session_id/leave", to: "sessions#leave"
  post "sessions/:session_id/sync", to: "sessions#sync"
  post "sessions/:session_id/chat", to: "sessions#chat"
  get "sessions/:session_id/status", to: "sessions#status"
end
