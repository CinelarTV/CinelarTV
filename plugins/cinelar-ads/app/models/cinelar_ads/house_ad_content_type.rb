# frozen_string_literal: true

module CinelarAds
  class HouseAdContentType < ApplicationRecord
    self.table_name = "cinelar_ads_house_ad_content_types"

    belongs_to :house_ad, class_name: "CinelarAds::HouseAd"

    validates :content_type, presence: true, inclusion: { in: %w[MOVIE TVSHOW] }
    validates :house_ad_id, uniqueness: { scope: :content_type }
  end
end
