# config/initializers/plugin_loader.rb
# Inicializa los plugins activos usando PluginManager

require Rails.root.join('lib', 'plugin_manager')

module PluginLoader
  @loaded_plugins = []

  def self.load_plugins
    @loaded_plugins.clear
    
    # Load ALL plugins (not just enabled ones) so engines are registered
    # Each plugin should check its own enabled status internally
    PluginManager.all_plugins.each do |plugin|
      begin
        # Avoid double-loading
        next if @loaded_plugins.include?(plugin[:folder])
        
        require plugin[:path]
        @loaded_plugins << plugin[:folder]
        Rails.logger.info("[PluginLoader] Loaded plugin: #{plugin[:folder]}")
      rescue => e
        Rails.logger.error("[PluginLoader] Failed to load plugin #{plugin[:folder]}: #{e.message}")
        Rails.logger.error(e.backtrace.first(5).join("\n"))
      end
    end
  end

  def self.loaded_plugins
    @loaded_plugins
  end
end

# Load plugins at the end of initialization
PluginLoader.load_plugins
