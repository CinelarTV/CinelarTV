# frozen_string_literal: true

module CinelarAds
  class AdImpression < ApplicationRecord
    self.table_name = "cinelar_ads_ad_impressions"

    belongs_to :house_ad, class_name: "CinelarAds::HouseAd", optional: true
    belongs_to :user, optional: true

    AD_TYPES = %w[house adsense admanager adterra].freeze

    validates :ad_type, presence: true, inclusion: { in: AD_TYPES }
    validates :placement, presence: true

    scope :recent,        ->(days = 30) { where("created_at > ?", days.days.ago) }
    scope :for_placement, ->(placement) { where(placement: placement) }
    scope :for_ad_type,   ->(ad_type)   { where(ad_type: ad_type) }
    scope :clicked,       ->            { where.not(clicked_at: nil) }

    # Track a new impression.
    #
    # Accepts either:
    #   house_ad_id: integer  — looked up and assigned to the belongs_to
    #   house_ad:    record   — assigned directly
    #
    # The controller sends params[:house_ad_id] (an integer from the JSON
    # body), so we support that here rather than requiring the caller to do
    # a separate find.
    def self.track!(ad_type:, placement:, house_ad_id: nil, house_ad: nil, user: nil, request: nil)
      resolved_house_ad = house_ad || (house_ad_id.present? ? CinelarAds::HouseAd.find_by(id: house_ad_id) : nil)

      create!(
        ad_type:    ad_type,
        placement:  placement,
        house_ad:   resolved_house_ad,
        user:       user,
        ip_address: request&.remote_ip
      )
    end

    def track_click!
      update(clicked_at: Time.current) if clicked_at.nil?
    end

    def clicked?
      clicked_at.present?
    end
  end
end
