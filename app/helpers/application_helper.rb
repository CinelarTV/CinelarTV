# frozen_string_literal: true

module ApplicationHelper
  def device
    agent = request.user_agent
    return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
    return "mobile" if agent =~ /Mobile/

    "desktop"
  end

  def preloaded_json
    exposed_settings = SiteSetting.exposed_settings

    @current_user = current_user
    @current_profile = current_profile
    user_with_profile = @current_user.as_json(include: {
                                                profiles: {
                                                  include: :preferences,
                                                },
                                              })

    if @current_user
      user_with_profile = user_with_profile.merge({
                                                    admin: @current_user.has_role?(:admin),
                                                  })
    end

    user_with_profile = user_with_profile.merge(current_profile: @current_profile) if @current_profile

    subscription_data = UserSubscription.find_by(user_id: @current_user.id) if @current_user

    user_with_profile = user_with_profile.merge(subscription: subscription_data) if subscription_data

    @preloaded_json = {
      SiteSettings: exposed_settings,
      isMobile: device == "mobile",
      currentUser: user_with_profile,
    }

    # If path is /, we are on the homepage, so we can preload content
    @preloaded_json[:homepageData] = homepage_data if request.path == "/"

    @preloaded_json.to_json.html_safe
  end

  def include_splash?
    SiteSetting.enable_splash_screen
  end

  def render_external_scripts
    external_scripts = SiteSetting.external_scripts || ""
    scripts = external_scripts.split("|")

    scripts << "https://app.lemonsqueezy.com/js/lemon.js" if SiteSetting.enable_subscription

    if SiteSetting.enable_chromecast
      scripts << "https://www.gstatic.com/cv/js/sender/v1/cast_sender.js?loadCastFramework=1"
    end

    scripts.map do |script|
      javascript_include_tag(script, defer: true)
    end.join.html_safe
  end

  def render_external_stylesheets
    external_stylesheets = SiteSetting.external_stylesheets || ""
    stylesheets = external_stylesheets.split("|")

    stylesheets.map do |stylesheet|
      stylesheet_link_tag(stylesheet)
    end.join.html_safe
  end
end
