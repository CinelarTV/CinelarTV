# frozen_string_literal: true

# Integration for plugin frontend assets with Vite
# Note: This must be loaded before Rails freezes the middleware stack

# Register plugin assets in production
if Rails.env.production?
  # In production, plugin assets are compiled by Vite and served from public/assets
  Rails.application.config.assets.precompile += Dir[
    Rails.root.join('plugins', '*', 'assets', '**', '*.{js,css,ts,scss,sass}')
  ]
end

# Add plugin paths to asset pipeline for development
if Rails.env.development?
  Rails.application.config.assets.paths += Dir[
    Rails.root.join('plugins', '*', 'assets', 'javascripts'),
    Rails.root.join('plugins', '*', 'assets', 'stylesheets')
  ]
end

# Configure plugin asset middleware for development
# Note: This must be done before the middleware stack is frozen
if Rails.env.development?
  Rails.application.config.middleware.insert_before 0, ActionDispatch::Static, 
    Rails.root.join('plugins').to_s,
    headers: { 'Cache-Control' => 'public, max-age=3600' }
end

# Vite plugin integration
if defined?(ViteRuby)
  ViteRuby.configure do |vite|
    # Add plugin directories to Vite's resolve paths
    plugin_dirs = Dir[Rails.root.join('plugins', '*')].select { |dir| Dir.exist?(dir) }
    
    plugin_dirs.each do |plugin_dir|
      plugin_name = File.basename(plugin_dir)
      
      # Add plugin assets to Vite's resolve
      vite.resolve_alias["@#{plugin_name}"] = plugin_dir.to_s
      
      # Add plugin TypeScript paths if tsconfig exists
      tsconfig_path = File.join(plugin_dir, 'tsconfig.json')
      if File.exist?(tsconfig_path)
        vite.config_options[:tsconfig] = tsconfig_path
      end
    end
  end
end
