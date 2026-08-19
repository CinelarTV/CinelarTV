# frozen_string_literal: true

module Plugin
  # The browser import map may only expose these reviewed contracts. Keeping the
  # list server-side makes an arbitrary `externals` declaration non-executable.
  module PublicPackages
    PACKAGES = {
      "@cinelartv/ui" => "entrypoints/cinelartv-ui.ts",
      "@cinelartv/core" => "entrypoints/cinelartv-core.ts",
      "@cinelartv/plugin-api" => "entrypoints/cinelartv-plugin-api.ts",
      # Runtime singletons are intentionally mapped too. A separately built
      # Vue SFC imports `vue`; mapping that bare specifier prevents a second
      # Vue/Pinia/router instance from being bundled by the plugin.
      "vue" => "entrypoints/cinelartv-vue.ts",
      "pinia" => "entrypoints/cinelartv-pinia.ts",
      "vue-router" => "entrypoints/cinelartv-vue-router.ts"
    }.freeze

    def self.names
      PACKAGES.keys
    end
  end
end
