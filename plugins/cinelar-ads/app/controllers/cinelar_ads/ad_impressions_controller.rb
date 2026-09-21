# frozen_string_literal: true

module CinelarAds
  class AdImpressionsController < ApplicationController
    IMPRESSION_RATE_LIMIT = 30 # per minute

    def create
      return head :forbidden unless SiteSetting.cinelar_ads_tracking_enabled

      impression = CinelarAds::AdImpression.track!(
        ad_type: params[:ad_type],
        placement: params[:placement],
        house_ad_id: params[:house_ad_id],
        user: current_user,
        request: request
      )

      render json: { id: impression.id }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def track_click
      return head :forbidden unless SiteSetting.cinelar_ads_tracking_enabled

      impression = CinelarAds::AdImpression.find(params[:id])
      impression.track_click!

      head :ok
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def reports
      return head :forbidden unless current_user&.is_admin?

      period = (params[:period] || 30).to_i
      impressions = CinelarAds::AdImpression.recent(period)

      render json: {
        total_impressions: impressions.count,
        total_clicks: impressions.clicked.count,
        by_type: impressions.group(:ad_type).count,
        by_placement: impressions.group(:placement).count,
        ctr_by_type: calculate_ctr(impressions, :ad_type),
        ctr_by_placement: calculate_ctr(impressions, :placement),
        daily_impressions: impressions.group("DATE(created_at)").count,
        daily_clicks: impressions.clicked.group("DATE(clicked_at)").count,
        top_house_ads: top_house_ads(impressions, period)
      }
    end

    private

    def calculate_ctr(impressions, group_by)
      total = impressions.group(group_by).count
      clicked = impressions.clicked.group(group_by).count

      total.transform_values do |count|
        group_key = total.key(count)
        click_count = clicked[group_key] || 0
        count > 0 ? (click_count.to_f / count * 100).round(2) : 0
      end
    end

    def top_house_ads(impressions, period)
      CinelarAds::AdImpression
        .where(ad_type: "house")
        .recent(period)
        .joins(:house_ad)
        .group("cinelar_ads_house_ads.name")
        .order("count_id DESC")
        .limit(10)
        .count(:id)
    end
  end
end
