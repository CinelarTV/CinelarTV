# frozen_string_literal: true

module Plugin
  class AssetManager
    class << self
      # Register plugin assets for Vite compilation
      def register_plugin_assets
        # Vite ya maneja los assets con el alias @plugins
        # Solo necesitamos asegurarnos que los archivos existan
        Rails.logger.info "[Plugin::AssetManager] Vite handles plugin assets via @plugins alias"
      end

      # Get plugin assets paths for frontend
      def plugin_assets
        # En desarrollo, Vite sirve los archivos directamente
        # En producción, se compilan y sirven desde public/assets
        {
          javascripts: [],
          stylesheets: []
        }
      end

      # Generate Vite entry points for plugins
      def generate_vite_entries
        entries = {}
        
        PluginRegistry.javascripts.each do |js_path|
          plugin_name = extract_plugin_name_from_path(js_path)
          entry_name = "plugin-#{plugin_name.dasherize}"
          
          full_path = Rails.root.join('plugins', plugin_name, js_path)
          if File.exist?(full_path)
            entries[entry_name] = full_path.to_s
          end
        end
        
        entries
      end

      # Update Vite config with plugin entries
      def update_vite_config!
        vite_config_path = Rails.root.join('vite.config.ts')
        return unless File.exist?(vite_config_path)

        entries = generate_vite_entries
        return if entries.empty?

        # Read current config
        config_content = File.read(vite_config_path)
        
        # Add plugin entries to build.rollupOptions.input
        if config_content.include?('build.rollupOptions')
          # Append to existing rollupOptions
          config_content = append_to_rollup_options(config_content, entries)
        else
          # Add new rollupOptions section
          config_content = add_rollup_options(config_content, entries)
        end

        File.write(vite_config_path, config_content)
      end

      private

      def extract_plugin_name_from_path(asset_path)
        parts = asset_path.split('/')
        # Find the plugin name (first directory after 'plugins/')
        plugin_index = parts.index { |part| part != 'plugins' && parts.index(part) > 0 }
        plugin_index ? parts[plugin_index] : parts.first
      end

      def register_vite_entry(asset_path)
        plugin_name = extract_plugin_name_from_path(asset_path)
        entry_name = "plugin-#{plugin_name.dasherize}"
        
        Rails.logger.info("[PluginAssetManager] Registered Vite entry: #{entry_name} -> #{asset_path}")
      end

      def append_to_rollup_options(config_content, entries)
        entries_str = entries.map { |name, path| "      '#{name}': '#{path}'" }.join(",\n")
        
        if config_content.include?('input:')
          # Append to existing input
          config_content.gsub(/(input:\s*\{)/, "\\1\n#{entries_str},\n")
        else
          # Add input to existing rollupOptions
          config_content.gsub(/(rollupOptions:\s*\{)/, "\\1\n    input: {\n#{entries_str}\n    },\n")
        end
      end

      def add_rollup_options(config_content, entries)
        entries_str = entries.map { |name, path| "      '#{name}': '#{path}'" }.join(",\n")
        
        rollup_options = <<~RUBY
          build: {
            rollupOptions: {
              input: {
        #{entries_str}
              }
            }
          },
        RUBY

        config_content.gsub(/(export default defineConfig\(\{)/, "\\1\n  #{rollup_options.strip}\n")
      end
    end
  end
end
