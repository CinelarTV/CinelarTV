# frozen_string_literal: true

module ::WatchParty
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace WatchParty

    config.autoload_paths << File.join(config.root, "lib")
    config.autoload_paths << File.join(config.root, "app", "controllers")
    config.autoload_paths << File.join(config.root, "app", "models")

    # Register plugin migrations so they run with db:migrate
    initializer "watch_party.register_migrations" do |app|
      app.config.paths["db/migrate"] ||= []
      plugin_migrate_path = File.join(config.root, "db", "migrate")
      app.config.paths["db/migrate"] << plugin_migrate_path unless app.config.paths["db/migrate"].include?(plugin_migrate_path)
    end
  end
end
