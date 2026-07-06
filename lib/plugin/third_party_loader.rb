# frozen_string_literal: true

require "json"

module Plugin
  class ThirdPartyLoader
    MANIFEST_PATH = Rails.root.join("public", "plugins", "manifest.json")

    class << self
      def installed_plugins
        return @plugins if defined?(@plugins)

        @plugins = if File.exist?(MANIFEST_PATH)
          JSON.parse(File.read(MANIFEST_PATH))
        else
          []
        end
      end

      def reset!
        remove_instance_variable(:@plugins) if defined?(@plugins)
      end

      def enabled?
        defined?(::SiteSetting) && ::SiteSetting.respond_to?(:enable_plugins) && ::SiteSetting.enable_plugins
      end

      def js_entries
        return [] unless enabled?

        installed_plugins.flat_map do |plugin|
          plugin["js"].map { |js| "/plugins/#{plugin['name']}/#{js}" }
        end
      end

      def css_entries
        return [] unless enabled?

        installed_plugins.flat_map do |plugin|
          plugin["css"].map { |css| "/plugins/#{plugin['name']}/#{css}" }
        end
      end
    end
  end
end
