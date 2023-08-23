# frozen_string_literal: true

class MetadataController < ApplicationController
  layout false

  def webmanifest
    expires_in 1.minutes
    render json: default_webmanifest.to_json, content_type: "application/manifest+json"
  end

  private

  def default_webmanifest
    display = "standalone"
    {
      name: SiteSetting.site_name,
      short_name: SiteSetting.site_name.truncate(12, separator: " ", omission: ""),
      display: display,
      start_url: "/",
      background_color: SiteSetting.background_color,
      theme_color: SiteSetting.header_background_color,
      icons: [
        {
          src: SiteSetting.site_mobile_logo,
          sizes: "512x512",
          type: "image/png",
          purpose: "any",
        },
      ],
      shortcuts: [
        {
          name: I18n.t("js.nav.explore"),
          short_name: I18n.t("js.nav.explore"),
          url: "/explore",
        },
        {
          name: I18n.t("js.nav.search"),
          short_name: I18n.t("js.nav.search"),
          url: "/search",
        },
        {
          name: I18n.t("js.nav.my_collection"),
          short_name: I18n.t("js.nav.my_collection"),
          url: "/collections",
        },
      ],
    }
  end
end
