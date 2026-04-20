# frozen_string_literal: true

module Plugin
  class AssetManager
    class << self
      # Plugin assets are handled automatically by Vite with @plugins alias
      # No manual asset management needed
      def register_plugin_assets
        Rails.logger.info "[Plugin::AssetManager] Vite handles plugin assets automatically via @plugins alias"
      end
    end
  end
end
