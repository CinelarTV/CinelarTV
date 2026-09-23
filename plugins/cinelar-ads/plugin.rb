# frozen_string_literal: true

# name: cinelar-ads
# version: 0.1.0
# authors: CinelarTV
# url: https://github.com/cinelartv/cinelar-ads
# required_version: 1.0.0

enabled_site_setting :cinelar_ads_enabled
register_svg_icon "ad"


# Models, controllers and serializers under app/ are loaded automatically by
# Rails autoloader — no require_relative needed here.
#
# Assets (register_js / register_css) are auto-scanned by activate! —
# no manual calls needed here either.

after_initialize do
  # Inject house_creatives into the /site.json payload so the frontend
  # AdSlot component can display house ads without a separate API call.
  # register_site_payload is preferred over register_serializer_extension
  # for site-level data because SiteController builds a plain Hash, not
  # an ActiveRecord-backed object.
  register_site_payload(:house_creatives) do
    next unless SiteSetting.cinelar_ads_enabled
    CinelarAds::HouseAdSetting.settings_and_ads
  end
end
