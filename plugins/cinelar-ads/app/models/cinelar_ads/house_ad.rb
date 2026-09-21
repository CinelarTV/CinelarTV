# frozen_string_literal: true

module CinelarAds
  class HouseAd < ApplicationRecord
    self.table_name = "cinelar_ads_house_ads"

    has_many :house_ad_categories, dependent: :destroy, class_name: "CinelarAds::HouseAdCategory"
    has_many :categories, through: :house_ad_categories, class_name: "Category"

    has_many :house_ad_content_types, dependent: :destroy, class_name: "CinelarAds::HouseAdContentType"
    has_many :impressions, class_name: "CinelarAds::AdImpression", foreign_key: :house_ad_id

    has_many :house_ad_settings, through: :house_ad_categories, class_name: "CinelarAds::HouseAdSetting"

    validates :name, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9_\- ]+\z/, message: "only allows letters, numbers, spaces, hyphens and underscores" }
    validates :html, presence: true

    before_save :sanitize_html

    scope :visible_to_anons, -> { where(visible_to_anons: true) }
    scope :visible_to_logged_in, -> { where(visible_to_logged_in_users: true) }

    def self.visible_to(user)
      if user.nil?
        visible_to_anons
      else
        visible_to_logged_in
      end
    end

    def self.for_category(category_id)
      joins(:house_ad_categories).where(cinelar_ads_house_ad_categories: { category_id: category_id })
    end

    def self.for_content_type(content_type)
      joins(:house_ad_content_types).where(cinelar_ads_house_ad_content_types: { content_type: content_type })
    end

    def self.for_slot(slot_name)
      joins(:house_ad_settings).where(cinelar_ads_house_ad_settings: { slot: slot_name })
    end

    def for_category?(category_id)
      return true if house_ad_categories.empty?

      house_ad_categories.exists?(category_id: category_id)
    end

    def for_content_type?(content_type)
      return true if house_ad_content_types.empty?

      house_ad_content_types.exists?(content_type: content_type)
    end

    private

    def sanitize_html
      return if html.blank?

      # Strip dangerous tags
      self.html = html
        .gsub(/<script[\s\S]*?<\/script>/mi, "")
        .gsub(/<noscript[\s\S]*?<\/noscript>/mi, "")
        .gsub(/<base[\s\S]*?\/?>/mi, "")
        .gsub(/javascript:/mi, "")
    end
  end
end
