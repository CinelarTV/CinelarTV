# frozen_string_literal: true

module CinelarAds
  class HouseAdSetting < ApplicationRecord
    self.table_name = "cinelar_ads_house_ad_settings"

    SLOTS = %w[
      home_before_carousel
      home_after_carousel
      home_between_rows
      content_below_actions
      content_below_related
      explore_top
    ].freeze

    validates :slot, presence: true, inclusion: { in: SLOTS }
    validates :ad_names, presence: true

    after_save    :publish_settings
    after_destroy :publish_settings

    def self.settings_and_ads
      settings = all.index_by(&:slot)
      result = {}

      SLOTS.each do |slot_name|
        setting = settings[slot_name]
        next unless setting

        ad_names = setting.ad_names.split("|").map(&:strip).reject(&:blank?)
        ads = CinelarAds::HouseAd.where(name: ad_names).to_a

        # Preserve the pipe-delimited order from the setting
        ordered_ads = ad_names.filter_map { |name| ads.find { |a| a.name == name } }

        result[slot_name] = {
          ad_names: ad_names,
          ads: ordered_ads.map { |ad|
            {
              id:                        ad.id,
              name:                      ad.name,
              html:                      ad.html,
              visible_to_anons:          ad.visible_to_anons,
              visible_to_logged_in_users: ad.visible_to_logged_in_users
            }
          }
        }
      end

      result
    end

    private

    # Publish updated creatives over MessageBus so connected clients receive
    # the change without a full page reload.
    #
    # Guards:
    #   1. MessageBus must be defined (gem present).
    #   2. MessageBus must be configured (backend not nil).  In test / fresh
    #      boots the backend may be absent even when the constant is defined.
    #   3. Errors are rescued so a failed publish never rolls back the save.
    def publish_settings
      return unless defined?(MessageBus)
      return unless MessageBus.respond_to?(:backend_instance) && MessageBus.backend_instance

      payload = self.class.settings_and_ads
      MessageBus.publish("/site/house-creatives", payload)
    rescue StandardError => e
      Rails.logger.warn("[CinelarAds] MessageBus publish failed: #{e.class} — #{e.message}")
    end
  end
end
