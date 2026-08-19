# frozen_string_literal: true

module ::WatchParty
  class Engine < ::Rails::Engine
    engine_name "cinelar-watchparty"
    isolate_namespace WatchParty

    # Add autoload paths safely via initializer (avoids frozen array errors
    # when the engine is loaded during before_initialize).
    initializer "watch_party.autoload_paths" do |app|
      app.config.autoload_paths << File.join(config.root, "lib") if Dir.exist?(File.join(config.root, "lib"))
    end

    # Register plugin migrations so they run with db:migrate
    initializer "watch_party.register_migrations" do |app|
      plugin_migrate_path = File.join(config.root, "db", "migrate")
      if Dir.exist?(plugin_migrate_path) && !app.config.paths["db/migrate"].include?(plugin_migrate_path)
        app.config.paths["db/migrate"] << plugin_migrate_path
      end
    end
  end
end
