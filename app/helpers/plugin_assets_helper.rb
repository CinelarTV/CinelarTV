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
end
