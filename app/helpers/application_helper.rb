# frozen_string_literal: true

require "uri"

module ApplicationHelper
  def device
    agent = request.user_agent
    return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
    return "mobile" if agent =~ /Mobile/

    "desktop"
  end

  def preloaded_json
    user_data = build_user_data

    preloaded = {
      SiteSettings: SiteSetting.exposed_settings,
      isMobile: device == "mobile",
      currentUser: user_data,
    }

    preloaded[:homepageData] = homepage_data if request.path == "/"

    preloaded.to_json.html_safe
  end

  def include_splash?
    SiteSetting.enable_splash_screen
  end

  def render_external_scripts
    scripts = (SiteSetting.external_scripts || "").split("|")
    scripts << "https://www.gstatic.com/cv/js/sender/v1/cast_sender.js?loadCastFramework=1" if SiteSetting.enable_chromecast
    scripts << "https://app.lemonsqueezy.com/js/lemon.js" if SiteSetting.enable_lemon_squeezy_provider

    scripts.map { |s| javascript_include_tag(s, defer: true) }.join.html_safe
  end

  def render_external_stylesheets
    (SiteSetting.external_stylesheets || "").split("|").map do |stylesheet|
      stylesheet_link_tag(stylesheet)
    end.join.html_safe
  end

  def resolve_stream_url(url)
    return url if url.blank?
    return url unless SiteSetting.live_tv_proxy_mode.to_s == "internal"
    return url unless request.ssl?
    return url if https_url?(url)

    live_proxy_path(url: url)
  end

  private

  def https_url?(url)
    parsed = URI.parse(url)
    parsed.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def build_user_data
    return nil unless current_user

    CurrentUserSerializer.new(current_user, {
      include_profiles: true,
      current_profile_id: session[:current_profile_id]
    }).serializable_hash
  end
end