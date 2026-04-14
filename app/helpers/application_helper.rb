# frozen_string_literal: true

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
    scripts << "https://app.lemonsqueezy.com/js/lemon.js" if SiteSetting.enable_subscription
    scripts << "https://www.gstatic.com/cv/js/sender/v1/cast_sender.js?loadCastFramework=1" if SiteSetting.enable_chromecast

    scripts.map { |s| javascript_include_tag(s, defer: true) }.join.html_safe
  end

  def render_external_stylesheets
    (SiteSetting.external_stylesheets || "").split("|").map do |stylesheet|
      stylesheet_link_tag(stylesheet)
    end.join.html_safe
  end

  private

  def build_user_data
    return nil unless current_user

    user_json = current_user.as_json(include: { profiles: { include: :preferences } })

    extras = { admin: current_user.has_role?(:admin) }
    extras[:current_profile] = current_profile if current_profile
    extras[:subscription] = UserSubscription.find_by(user_id: current_user.id)

    user_json.merge(extras.compact)
  end
end