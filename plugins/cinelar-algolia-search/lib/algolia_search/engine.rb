# frozen_string_literal: true

module ::AlgoliaSearchPlugin
  class Engine < ::Rails::Engine
    engine_name "cinelar-algolia-search"
    isolate_namespace AlgoliaSearchPlugin

    initializer "algolia_search_plugin.autoload_paths" do |app|
      app.config.autoload_paths << File.join(config.root, "lib") if Dir.exist?(File.join(config.root, "lib"))
    end

    initializer "algolia_search_plugin.register_migrations" do |app|
      plugin_migrate_path = File.join(config.root, "db", "migrate")
      if Dir.exist?(plugin_migrate_path) && !app.config.paths["db/migrate"].include?(plugin_migrate_path)
        app.config.paths["db/migrate"] << plugin_migrate_path
      end
    end
  end
end
