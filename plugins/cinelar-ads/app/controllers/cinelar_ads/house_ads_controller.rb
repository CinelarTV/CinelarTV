# frozen_string_literal: true

module CinelarAds
  class HouseAdsController < ApplicationController
    skip_forgery_protection
    wrap_parameters false

    before_action :authenticate_user!, except: [:index]
    before_action :ensure_admin!, except: [:index]
    before_action :set_house_ad, only: [:show, :update, :destroy]

    def index
      ads = CinelarAds::HouseAd.order(:name)

      if params[:slot].present?
        ads = ads.for_slot(params[:slot])
      end

      render json: ads.map { |ad| serialize_ad(ad) }, root: false
    end

    def show
      render json: serialize_ad(@house_ad, detailed: true), root: false
    end

    def create
      ad = CinelarAds::HouseAd.new(house_ad_params)

      if ad.save
        update_associations(ad)
        render json: serialize_ad(ad), status: :created, root: false
      else
        render json: { errors: ad.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @house_ad.update(house_ad_params)
        update_associations(@house_ad)
        render json: serialize_ad(@house_ad), root: false
      else
        render json: { errors: @house_ad.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @house_ad.destroy!
      render json: { ok: true }
    end

    private

    def set_house_ad
      @house_ad = CinelarAds::HouseAd.find(params[:id])
    end

    def house_ad_params
      params.permit(:name, :html, :visible_to_anons, :visible_to_logged_in_users)
    end

    def ensure_admin!
      unless current_user&.is_admin?
        render json: { error: "Forbidden" }, status: :forbidden
      end
    end

    def update_associations(ad)
      # Categories
      if params[:category_ids].present?
        ad.house_ad_categories.destroy_all
        params[:category_ids].each do |cat_id|
          ad.house_ad_categories.create(category_id: cat_id)
        end
      end

      # Content types
      if params[:content_types].present?
        ad.house_ad_content_types.destroy_all
        params[:content_types].each do |ct|
          ad.house_ad_content_types.create(content_type: ct)
        end
      end
    end

    def serialize_ad(ad, detailed: false)
      data = {
        id: ad.id,
        name: ad.name,
        html: ad.html,
        visible_to_anons: ad.visible_to_anons,
        visible_to_logged_in_users: ad.visible_to_logged_in_users,
        created_at: ad.created_at,
        updated_at: ad.updated_at
      }

      if detailed
        data[:categories] = ad.categories.map { |c| { id: c.id, name: c.name } }
        data[:content_types] = ad.house_ad_content_types.pluck(:content_type)
        data[:impression_count] = ad.impressions.count
        data[:click_count] = ad.impressions.clicked.count
      end

      data
    end
  end
end
