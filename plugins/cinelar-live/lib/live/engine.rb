# frozen_string_literal: true

class Live::Engine < ::Rails::Engine
  engine_name "cinelar-live"

  initializer "live.autoload_paths" do |app|
    app.config.autoload_paths << File.join(config.root, "lib") if Dir.exist?(File.join(config.root, "lib"))
  end

  initializer "live.register_migrations" do |app|
    plugin_migrate_path = File.join(config.root, "db", "migrate")
    if Dir.exist?(plugin_migrate_path) && !app.config.paths["db/migrate"].include?(plugin_migrate_path)
      app.config.paths["db/migrate"] << plugin_migrate_path
    end
  end
end
