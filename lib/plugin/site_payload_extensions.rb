# frozen_string_literal: true

module Plugin
  # Lightweight extension point for the /site.json payload.
  #
  # Unlike SerializerExtensionRegistry (which requires an ActiveRecord-backed
  # serializer), this module works with a plain Hash built by SiteController.
  #
  # Plugins register extensions in their plugin.rb:
  #
  #   register_site_payload(:house_creatives) do
  #     next unless SiteSetting.cinelar_ads_enabled
  #     CinelarAds::HouseAdSetting.settings_and_ads
  #   end
  #
  # Each block receives the controller as optional context and should return
  # the value to merge under the given key.  Returning nil skips the key.
  module SitePayloadExtensions
    MUTEX = Mutex.new

    class Extension
      attr_reader :key, :plugin_name, :block

      def initialize(key, plugin_name:, &block)
        @key         = key
        @plugin_name = plugin_name
        @block       = block
      end
    end

    class << self
      def register(key, plugin_name:, &block)
        ext = Extension.new(key, plugin_name: plugin_name, &block)
        MUTEX.synchronize { extensions << ext }
        ext
      end

      def extend_payload!(payload, controller: nil)
        MUTEX.synchronize { extensions.dup }.each do |ext|
          value = ext.block.call(controller)
        rescue StandardError => e
          Rails.logger.warn("[SitePayload] Extension '#{ext.key}' (#{ext.plugin_name}) raised: #{e.class} — #{e.message}")
          next
        else
          payload[ext.key] = value unless value.nil?
        end
        payload
      end

      def remove_by_plugin(plugin_name)
        MUTEX.synchronize { extensions.reject! { |e| e.plugin_name == plugin_name } }
      end

      def clear!
        MUTEX.synchronize { @extensions = [] }
      end

      private

      def extensions
        @extensions ||= []
      end
    end
  end
end
