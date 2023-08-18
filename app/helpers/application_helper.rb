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

        user_with_profile = current_user.to_h.merge(profile: current_profile)

        {
          SiteSettings: exposed_settings,
          isMobile: device == "mobile",
          currentUser: user_with_profile
        }.to_json
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
