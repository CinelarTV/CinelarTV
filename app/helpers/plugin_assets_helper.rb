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

    # Inline shim — no Vite entry point, no module imports, no circular deps.
    # Provides empty placeholders on window.CinelarTV so third-party plugin
    # <script type="module"> tags can be parsed without import errors.
    # boot-cinelartv.ts replaces these with real implementations after mount.
    shim = <<~JS.html_safe
      <script>
        (function() {
          var CT = window.CinelarTV = window.CinelarTV || {};
          CT.Vue = CT.Vue || {};
          CT.VueRouter = CT.VueRouter || {};
          CT.Pinia = CT.Pinia || {};
          CT.axios = CT.axios || {};
          CT.PluginEvents = CT.PluginEvents || { on:function(){return function(){}}, off:function(){}, emit:function(){} };
          CT.SiteSettings = CT.SiteSettings || {};
          CT.PluginOutlet = CT.PluginOutlet || { registerPluginOutlet:function(){} };
          CT.PluginOutlets = CT.PluginOutlets || {};
        })();
      </script>
    JS

    tags << shim

    Plugin::ThirdPartyLoader.js_entries.each do |path|
      tags << tag.script(src: path, type: "module", "data-turbo-track": "reload")
    end

    safe_join(tags)
  end
end
