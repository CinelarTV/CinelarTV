# lib/plugin_manager.rb
class PluginManager
  PLUGIN_DIR = Rails.root.join("plugins")

  # Devuelve un array de hashes con metadata de todos los plugins encontrados
  def self.all_plugins
    Dir.glob(PLUGIN_DIR.join("*/plugin.rb")).map do |plugin_file|
      meta = extract_metadata(plugin_file)
      meta[:path] = plugin_file
      meta[:folder] = File.basename(File.dirname(plugin_file))
      meta[:enabled] = plugin_enabled?(meta)
      meta
    end
  end

  # Extrae metadata de los comentarios del plugin.rb
  def self.extract_metadata(plugin_file)
    meta = {}
    File.foreach(plugin_file) do |line|
      next if line.strip == '# frozen_string_literal: true'
      break if line.strip == ""
      if line =~ /^#\s*(\w+):\s*(.+)$/i
        key, value = $1, $2
        meta[key.downcase.to_sym] = value.strip
      end
    end
    meta
  end

  # Determina si el plugin está habilitado según SiteSetting
  # During boot, SiteSetting may not have plugin settings merged yet,
  # so we default to enabled. Each plugin should check its own setting internally.
  def self.plugin_enabled?(meta)
    # Busca enabled_site_setting en el plugin.rb
    setting = nil
    File.foreach(meta[:path]) do |line|
      if line =~ /enabled_site_setting\s+:(\w+)/
        setting = $1.strip
        break
      end
    end
    return true unless setting

    # Check if SiteSetting is available and has the setting
    begin
      return true unless defined?(::SiteSetting)
      return true unless ::SiteSetting.respond_to?(setting)
      ::SiteSetting.send(setting)
    rescue => e
      Rails.logger.debug("[PluginManager] Could not check setting #{setting}: #{e.message}, defaulting to enabled")
      true
    end
  end

  # Devuelve solo los plugins activos
  def self.enabled_plugins
    all_plugins.select { |p| p[:enabled] }
  end
end