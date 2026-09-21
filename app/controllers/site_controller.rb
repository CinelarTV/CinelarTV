# frozen_string_literal: true

class SiteController < ApplicationController
  # GET /site.json
  #
  # Builds the site payload as a plain hash and then merges any attributes
  # registered by plugins via Plugin::SitePayloadExtensions.extend_payload!.
  #
  # This avoids passing a synthetic object (OpenStruct, Struct, etc.) to
  # ActiveModel::Serializer, which requires read_attribute_for_serialization
  # and other ActiveRecord-specific methods.
  def info
    payload = {
      site_name:     SiteSetting.site_name || "CinelarTV",
      logo_url:      SiteSetting.site_logo || view_context.asset_url("logo.png"),
      description:   "La mejor plataforma de streaming independiente",
      contact_email: "info@cinelartv.com",
      version:       (defined?(::CinelarTV::Application::Version) ? ::CinelarTV::Application::Version::FULL : nil)
    }

    Plugin::SitePayloadExtensions.extend_payload!(payload, controller: self)

    render json: payload
  end

  # GET /site/settings
  def settings
    render json: SiteSetting.exposed_settings
  end

  private

  def device
    agent = request.user_agent
    return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
    return "mobile" if agent =~ /Mobile/
    "desktop"
  end
end
