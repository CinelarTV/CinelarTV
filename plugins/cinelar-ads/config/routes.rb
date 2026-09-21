# frozen_string_literal: true

# Plugin routes for cinelar-ads.
#
# The `module:` option is critical: without it Rails would look for
# CinelarAdsController (top-level), but all controllers live under the
# CinelarAds:: module (CinelarAds::HouseAdsController, etc.).
namespace :cinelar_ads, module: "cinelar_ads", path: "cinelar_ads", constraints: { format: :json } do
  resources :house_ads, only: %i[index show create update destroy]

  get  "settings", to: "house_ad_settings#index"
  put  "settings", to: "house_ad_settings#update"

  resources :ad_impressions, only: %i[create] do
    member do
      patch :track_click
    end
  end

  get "reports", to: "ad_impressions#reports"
end

# Serve /ads.txt (plain text, no format constraint)
get "/ads.txt", to: "cinelar_ads/ad_impressions#ads_txt", defaults: { format: :text }
