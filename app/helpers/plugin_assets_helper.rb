# frozen_string_literal: true

module PluginAssetsHelper
  def render_third_party_plugins_css
    return unless Plugin::ThirdPartyLoader.enabled?

    tags = Plugin::ThirdPartyLoader.css_entries.map do |path|
      tag.link(rel: "stylesheet", href: path)
    end

    safe_join(tags)
  end

  def render_third_party_plugins_js
    return unless Plugin::ThirdPartyLoader.enabled?

    tags = []

    # Core modules entry point — must load before any third-party plugin script.
    # Provides window.CinelarTV.Vue, .Pinia, .PluginEvents, etc.
    tags << vite_typescript_tag("plugin-core")

    Plugin::ThirdPartyLoader.js_entries.each do |path|
      tags << tag.script(src: path, type: "module", "data-turbo-track": "reload")
    end

    safe_join(tags)
  end
end
