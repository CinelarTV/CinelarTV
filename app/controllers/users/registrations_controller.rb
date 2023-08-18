# frozen_string_literal: true

module Users
    class RegistrationsController < Devise::RegistrationsController
      before_action :configure_sign_up_params, only: [:create]
  
      def new
        build_resource({})
        resource.build_profile
        respond_with resource
      end
  
      def create
        @user = User.new(user_params)
        if @user.save
          # Create the main profile for the user
          main_profile_data = {
            user_id: @user.id,
            name: @user.username.upcase,
            profile_type: 'OWNER',
            avatar_id: 'default'
          }
          Profile.create(main_profile_data)
          # ... Additional logic for successful registration ...
        else
          # ... Logic for failed registration ...
        end
      end
  
      protected
  
      def sign_up_params
        devise_parameter_sanitizer.sanitize(:sign_up) { |user| user.permit(permitted_attributes) }
      end
  
      def configure_sign_up_params
        devise_parameter_sanitizer.permit(:sign_up, keys: permitted_attributes)
      end
  
      def permitted_attributes
        [
          :email,
          :password,
          :password_confirmation,
          :remember_me
        ]
      end
    end
  end
  