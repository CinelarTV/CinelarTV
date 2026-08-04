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

    tags = Plugin::ThirdPartyLoader.js_entries.map do |path|
      tag.script(src: path, type: "module", "data-turbo-track": "reload")
    end

    safe_join(tags)
  end
end
