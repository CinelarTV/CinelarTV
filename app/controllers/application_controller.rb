# frozen_string_literal: true

class ApplicationController < ActionController::Base
    def index
    end

    def refresh_settings
        SiteSetting.load_settings
        redirect_to app_path
    end

    def current_profile
        return @current_profile if defined?(@current_profile)
        
        if user_signed_in? && session[:current_profile_id].present?
          @current_profile ||= current_user.profiles.find_by(id: session[:current_profile_id])
        end
      end
      helper_method :current_profile

    
end
