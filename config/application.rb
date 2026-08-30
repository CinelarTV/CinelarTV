# frozen_string_literal: true

require_relative "boot"
require "rails/all"

require "dotenv/load" if File.exist?(File.expand_path("../.env", __dir__))

Bundler.require(*Rails.groups)

# Load plugin system before application configuration
require_relative "../lib/plugin/metadata"
require_relative "../lib/plugin/public_packages"
require_relative "../lib/plugin/manifest"
require_relative "../lib/plugin/dependency_resolver"
require_relative "../lib/plugin/registry"
require_relative "../lib/plugin/instance"
require_relative "../lib/plugin_gem"
require_relative "../lib/plugin/serializer_extensions"
require_relative "../lib/plugin/route_loader"
require_relative "../lib/plugin_registry"
require_relative "../lib/app_event"

module CinelarTV
  class Application < Rails::Application
    config.load_defaults 7.0

    config.autoload_paths << "#{root}/lib"
    config.autoload_paths << "#{root}/app/services"
    config.autoload_paths << "#{root}/app/sidekiq"
    config.eager_load_paths << "#{root}/app/services"
    config.eager_load_paths << "#{root}/app/sidekiq"

    # Plugin paths
    %w[controllers models services sidekiq].each do |layer|
      Dir.glob(Rails.root.join("plugins", "*", "app", layer)).each do |dir|
        config.autoload_paths << dir
        config.eager_load_paths << dir
      end
    end

    Dir.glob(Rails.root.join("plugins", "*", "db", "migrate")).each do |dir|
      config.paths["db/migrate"] << dir.to_s
    end

    # Activar plugins ANTES del boot completo (registra assets, migraciones, etc.)
    config.before_initialize do
      registry = Plugin::Registry.build
      registry.activate!
      config.x.plugin_registry = registry
      registry.records.select(&:enabled?).each do |record|
        plugin = record.instance
        CinelarTV.plugins << plugin
        CinelarTV.plugins_by_name[plugin.name] = plugin
      end
    end

    require "cinelar_tv"

    config.active_job.queue_adapter = :sidekiq

    require_relative "../app/middleware/block_scanner_requests"
    config.middleware.insert_before(Rails::Rack::Logger, BlockScannerRequests)

    # Ejecutar after_initialize de cada plugin DESPUÉS del boot completo
    config.after_initialize do
      CinelarTV.plugins.each(&:notify_after_initialize)
      
      AppEvent.trigger(:after_plugin_activation)
    end

   
  end
end
