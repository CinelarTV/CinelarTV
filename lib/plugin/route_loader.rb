# frozen_string_literal: true

module Plugin
  # Safely loads routes from enabled, compatible plugins. Only plugins whose
  # registry status is :enabled and whose manifest declares routes will be
  # evaluated. Engine mounting is handled here as well.
  #
  # This replaces the previously commented-out instance_eval loop in
  # config/routes.rb.
  class RouteLoader
    class << self
      # Call from inside Rails.application.routes.draw to mount plugin routes.
      # @param registry [Plugin::Registry] the active registry
      # @param context the routing DSL context (the block passed to draw)
      def load(registry: Rails.configuration.x.plugin_registry, context: Rails.application.routes)
        return unless registry

        registry.ordered.select(&:enabled?).each do |record|
          load_plugin_routes(record, context)
        rescue StandardError => e
          Rails.logger.error("[PluginRouteLoader] Failed to load routes for #{record.id}: #{e.message}")
        end
      end

      private

      def load_plugin_routes(record, context)
        manifest = record.manifest
        plugin_dir = manifest.path

        # Mount Rails Engine if declared
        engine_class_name = manifest.data.dig("backend", "engine")
        if engine_class_name.present?
          mount_engine(engine_class_name, plugin_dir, context)
        end

        # Load routes file if declared and present
        routes_relative = manifest.data.dig("backend", "routes")
        return unless routes_relative

        routes_file = File.join(plugin_dir, routes_relative)
        return unless File.exist?(routes_file)

        routes_content = File.read(routes_file)
        context.instance_eval(routes_content, routes_file)
      end

      def mount_engine(class_name, plugin_dir, context)
        engine_class = class_name.safe_constantize
        return unless engine_class
        return unless engine_class.respond_to?(:ancestors) && engine_class.ancestors.include?(::Rails::Engine)

        # Derive a mount path from the plugin id
        plugin_id = File.basename(plugin_dir)
        mount_path = "/#{plugin_id}"
        context.mount engine_class, at: mount_path
      rescue NameError => e
        Rails.logger.warn("[PluginRouteLoader] Engine class #{class_name} not found: #{e.message}")
      end
    end
  end
end
