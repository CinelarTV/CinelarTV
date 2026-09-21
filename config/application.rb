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
require_relative "../lib/plugin/site_payload_extensions"
require_relative "../lib/plugin/route_loader"
require_relative "../lib/plugin_registry"
require_relative "../lib/app_event"

module CinelarTV
  class Application < Rails::Application
    config.load_defaults 7.0

    # Use structure.sql instead of schema.rb.  This mirrors Discourse's approach:
    # plugin migrations are registered into ActiveRecord::Tasks::DatabaseTasks
    # .migrations_paths in Plugin::Instance#activate!, so they run with
    # db:migrate and are reflected in structure.sql just like core migrations.
    # No separate plugin:migrate task or plugin_schema_versions table needed.
    config.active_record.schema_format = :sql

    config.autoload_paths << "#{root}/lib"
    config.autoload_paths << "#{root}/app/services"
    config.autoload_paths << "#{root}/app/sidekiq"
    config.eager_load_paths << "#{root}/app/services"
    config.eager_load_paths << "#{root}/app/sidekiq"

    # Plugin paths (excluding concerns - plugins handle their own requires via plugin.rb)
    %w[controllers models services sidekiq].each do |layer|
      Dir.glob(Rails.root.join("plugins", "*", "app", layer)).each do |dir|
        config.autoload_paths << dir
        config.eager_load_paths << dir
      end
    end

    # Activar plugins ANTES del boot completo (registra assets, etc.)
    # Plugin#activate! also pushes each plugin's db/migrate directory into
    # ActiveRecord::Tasks::DatabaseTasks.migrations_paths so that db:migrate
    # picks them up automatically.
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
