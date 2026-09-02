# frozen_string_literal: true

module PluginAssetsHelper
  # Generated from Vite's manifest by `plugins:generate_importmap`. This must be
  # emitted before every module script so independently compiled plugins can
  # resolve @cinelartv/* without knowing fingerprinted asset URLs.
  def render_plugin_importmap
    if Rails.env.development?
      imports = Plugin::PublicPackages::PACKAGES.transform_values do |entry|
        vite_asset_path(entry, type: :typescript)
      end
      return content_tag(:script, { imports: imports }.to_json.html_safe, type: "importmap", nonce: true)
    end

    path = Rails.root.join("public", "vite", "cinelartv-plugin-importmap.json")
    return "" unless File.exist?(path)

    json = File.read(path)
    JSON.parse(json) # fail closed for an accidentally corrupted generated file
    content_tag(:script, json.html_safe, type: "importmap", nonce: true)
  rescue JSON::ParserError => e
    Rails.logger.error("[PluginImportmap] Invalid generated import map: #{e.message}")
    ""
  end

  def render_third_party_plugins_css
    return unless Plugin::ThirdPartyLoader.enabled?

    tags = Plugin::ThirdPartyLoader.css_entries.map do |path|
      tag.link(rel: "stylesheet", href: path)
    end

    safe_join(tags)
  end

  def render_third_party_plugins_js
    return unless Plugin::ThirdPartyLoader.enabled?

    tags = Plugin::ThirdPartyLoader.js_entries.map do |path|
      tag.script(src: path, type: "module", "data-turbo-track": "reload")
    end

    safe_join(tags)
  end

  def render_source_plugins_css
    manifest_path = Rails.root.join("public", "vite", ".vite", "manifest.json")
    if File.exist?(manifest_path)
      manifest = begin
        JSON.parse(File.read(manifest_path))
      rescue JSON::ParserError
        {}
      end

      css_files = []
      manifest.each do |key, value|
        if key.include?("plugins/") && value["css"]
          css_files.concat(value["css"])
        end
      end

      tags = css_files.uniq.map do |css_file|
        tag.link(rel: "stylesheet", href: "/vite/#{css_file}")
      end
      return safe_join(tags)
    end

    # Fallback for development mode if static CSS files are registered via Plugin::Instance
    tags = Plugin::Instance.registered_css.filter_map do |entry|
      relative = entry[:path].sub(Rails.root.to_s + "/", "")
      next unless File.exist?(entry[:path])

      tag.link(rel: "stylesheet", href: "/#{relative}", media: entry[:media])
    end

    safe_join(tags)
  end
end
