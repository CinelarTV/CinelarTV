# frozen_string_literal: true

module CinelarAds
  class HouseAdSettingsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin!

    def index
      settings = CinelarAds::HouseAdSetting.all.index_by(&:slot)

      render json: CinelarAds::HouseAdSetting::SLOTS.map { |slot|
        setting = settings[slot]
        {
          slot: slot,
          ad_names: setting&.ad_names || "",
          ads: setting ? setting.ad_names.split("|").map(&:strip).reject(&:blank?) : []
        }
      }
    end

    def update
      slot = params[:slot]
      ad_names = params[:ad_names] || ""

      unless CinelarAds::HouseAdSetting::SLOTS.include?(slot)
        return render json: { error: "Invalid slot" }, status: :unprocessable_entity
      end

      setting = CinelarAds::HouseAdSetting.find_or_initialize_by(slot: slot)
      setting.ad_names = ad_names

      if setting.save
        render json: { slot: slot, ad_names: setting.ad_names }
      else
        render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def ensure_admin!
      unless current_user&.is_admin?
        render json: { error: "Forbidden" }, status: :forbidden
      end
    end
  end
end
