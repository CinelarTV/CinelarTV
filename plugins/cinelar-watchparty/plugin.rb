# frozen_string_literal: true

# name: cinelar-watchparty
# version: 1.0.0
# authors: CinelarTV
# url: https://github.com/cinelartv/cinelar-watchparty
# required_version: 1.0.0

enabled_site_setting :cinelar_watchparty_enabled

after_initialize do
  # Agregar métodos a modelos existentes
  add_to_class(:user, :watchparty_sessions) do
    WatchParty::Session.where(user_id: id)
  end

  # Agregar callbacks
  add_model_callback(:user, :after_create) do
    Rails.logger.info("[WatchParty] User created: #{self.email}")
  end

  # Registrar assets del plugin
  register_js("app/index.ts")
  register_css("app/assets/styles/watchparty.css")

  # Registrar custom fields específicos de CinelarTV
  PluginRegistry.register_user_profile_field({
    name: "watchparty_preferences",
    type: "json",
    label: "WatchParty Preferences",
    description: "User preferences for WatchParty sessions"
  }, self)
  
  PluginRegistry.register_video_source_type({
    name: "watchparty_stream",
    label: "WatchParty Stream",
    description: "Live stream source for WatchParty sessions",
    handler: "WatchParty::StreamHandler"
  }, self)
  
  PluginRegistry.register_player_controls({
    name: "watchparty_controls",
    component: "WatchPartyControls",
    position: "top-right",
    description: "WatchParty session controls"
  }, self)

  # Suscribirse a eventos
  on(:user_created) do |user|
    Rails.logger.info("[WatchParty] New user can create watch parties: #{user.email}")
  end

  on(:content_playback_start) do |content, user|
    if enabled?
      WatchParty::SessionManager.handle_playback_start(content, user)
    end
  end

  # Registrar dashboard widget
  PluginRegistry.register_dashboard_widget({
    name: "watchparty_stats",
    title: "WatchParty Statistics",
    template: "watchparty/dashboard_stats",
    position: 5
  }, self)

  # Registrar menú item
  PluginRegistry.register_user_menu_item({
    label: "Watch Parties",
    path: "/watchparty",
    icon: "fas fa-users",
    position: 10
  }, self)
end

# Cargar el Rails Engine del plugin
require_relative "lib/watch_party/engine"
