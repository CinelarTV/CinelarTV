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

after_initialize do
  # Code to run after the application initialises
end
