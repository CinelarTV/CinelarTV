# frozen_string_literal: true

require_relative "boot"
require "rails/all"

require "dotenv/load" if File.exist?(File.expand_path("../.env", __dir__))

Bundler.require(*Rails.groups)

# Load plugin system before application configuration
require_relative "../lib/plugin/metadata"
require_relative "../lib/plugin/instance"
require_relative "../lib/plugin_registry"
require_relative "../lib/app_event"

module CinelarTV
  class Application < Rails::Application
    config.load_defaults 7.0

    config.autoload_paths << "#{root}/lib"
    config.autoload_paths << "#{root}/app/services"
    config.eager_load_paths << "#{root}/app/services"

    # Plugin paths
    %w[controllers models].each do |layer|
      Dir.glob(Rails.root.join("plugins", "*", "app", layer)).each do |dir|
        config.autoload_paths << dir
      end
    end

    Dir.glob(Rails.root.join("plugins", "*", "db", "migrate")).each do |dir|
      config.paths["db/migrate"] << dir.to_s
    end

    # Activar plugins ANTES del boot completo (registra assets, migraciones, etc.)
    config.before_initialize do
      Plugin::Instance
        .find_all(Rails.root.join("plugins").to_s)
        .each do |plugin|
          plugin.activate!
          CinelarTV.plugins << plugin
          CinelarTV.plugins_by_name[plugin.name] = plugin
        end
    end

    require "cinelar_tv"

    config.active_job.queue_adapter = :sidekiq

    require_relative "../app/middleware/silence_live_proxy_logger"
    config.middleware.insert_before(Rails::Rack::Logger, SilenceLiveProxyLogger)

    # Ejecutar after_initialize de cada plugin DESPUÉS del boot completo
    config.after_initialize do
      CinelarTV.plugins.each(&:notify_after_initialize)
      
      AppEvent.trigger(:after_plugin_activation)
    end

   
  end
end