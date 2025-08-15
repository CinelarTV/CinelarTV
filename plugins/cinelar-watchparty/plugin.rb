# frozen_string_literal: true

# name: CinelarTV WatchParty
# about: Make your own WatchParty with CinelarTV
# version: 0.1
# authors: CinelarTV
# url: null

# enabled_site_setting :cinelar_watchparty_enabled

module ::WatchParty
  PLUGIN_NAME = "cinelartv-watch-party"
end

require_relative "lib/watch_party/engine"

# Usar el hook estándar de Rails para inicialización de plugins
Rails.application.config.after_initialize do
  # Añadir rutas del engine si no están ya montadas
  unless Rails.application.routes.named_routes.key?(:watch_party)
    WatchParty::Engine.routes.draw do
      get "watch_party", to: "watch_party#index"
    end
  end
end
