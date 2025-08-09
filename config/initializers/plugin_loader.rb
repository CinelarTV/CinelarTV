# config/initializers/plugin_loader.rb
# Inicializa los plugins activos usando PluginManager

require Rails.root.join('lib', 'plugin_manager')

module PluginLoader
  @loaded_plugins = []

  def self.load_plugins
    @loaded_plugins.clear
    PluginManager.enabled_plugins.each do |plugin|
      require plugin[:path]
      @loaded_plugins << plugin[:folder]
      Rails.logger.info("[PluginLoader] Loaded plugin: #{plugin[:folder]}")
    end
  end

  def self.reload_plugins
    # No hay un mecanismo estándar para descargar código en Ruby,
    # pero puedes recargar settings y volver a cargar los plugins activos
    load_plugins
    Rails.logger.info("[PluginLoader] Plugins reloaded.")
  end

  def self.loaded_plugins
    @loaded_plugins
  end
end

# Carga los plugins al iniciar la app
PluginLoader.load_plugins
