# frozen_string_literal: true

class ApplicationController < ActionController::Base

  before_action :reload_storage_config


    # Crea un before_action, si el usuario está logueado, pero no tiene un perfil seleccionado, lo redirige a la página de selección de perfil.
    #before_action :check_profile_if_signed_in

    def index
    end

    def refresh_settings
        SiteSetting.reload_settings
        redirect_to app_path
    end

    def current_profile
        return @current_profile if defined?(@current_profile)
        
        if user_signed_in? && session[:current_profile_id].present?
          @current_profile ||= current_user.profiles.find_by(id: session[:current_profile_id])
        end
      end
      helper_method :current_profile

      private 

      def check_profile_if_signed_in
        # Ignore if request is POST or JSON format
        return if request.post? || request.format.json? 
        @select_profile_path = '/profiles/select'
        return if request.path == @select_profile_path # Agrega esta línea para evitar el bucle
        if user_signed_in? && !current_profile
          redirect_to @select_profile_path # Cambia "select_profile_path" a la ruta adecuada
        end
      end

      def reload_storage_config
        Rails.logger.info("Reloading storage config")
        BaseUploader.configure_storage
      end
end
