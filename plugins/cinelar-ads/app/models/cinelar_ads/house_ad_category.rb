# frozen_string_literal: true

module CinelarAds
  class HouseAdCategory < ApplicationRecord
    self.table_name = "cinelar_ads_house_ad_categories"

    belongs_to :house_ad, class_name: "CinelarAds::HouseAd"
    belongs_to :category, class_name: "Category"

    validates :house_ad_id, uniqueness: { scope: :category_id }
  end
end
