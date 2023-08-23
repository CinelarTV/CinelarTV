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
    puts "current_profile: #{@current_profile}"
    user_with_profile = @current_user.as_json(include: {
                                                profiles: {
                                                  include: :preferences,
                                                },
                                              })

    if (@current_user)
      user_with_profile = user_with_profile.merge({
        admin: @current_user.has_role?(:admin),
      })
    end

    if @current_profile
      user_with_profile = user_with_profile.merge(current_profile: @current_profile)
    end

    @preloaded_json = {
      SiteSettings: exposed_settings,
      isMobile: device == "mobile",
      currentUser: user_with_profile,
    }

    # If path is /, we are on the homepage, so we can preload content
    if request.path == "/"
      @preloaded_json[:homepageData] = Content.homepage_data
    end

    @preloaded_json.to_json.html_safe
  end

  def include_splash?
    SiteSetting.enable_splash_screen
  end

  def render_external_scripts
    external_scripts = SiteSetting.external_scripts || ""
    scripts = external_scripts.split("|")

    scripts.map do |script|
      javascript_include_tag(script)
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
