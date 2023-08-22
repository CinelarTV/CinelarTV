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
        @user = User.new(sign_up_params)
      
        if @user.save
          main_profile_data = {
            user_id: @user.id,
            name: @user.username.upcase,
            profile_type: 'OWNER',
            avatar_id: 'coolCat' # Default avatar
          }
          Profile.create(main_profile_data)
      
          if SiteSetting.waiting_on_first_user && @user.email == SiteSetting.developer_email
            @user.add_role(:super_admin)
            SiteSetting.waiting_on_first_user = false
          end
      
          respond_to do |format|
            format.json { render json: @user, status: :created }
            sign_in(@user) # Sign in the newly registered user
            format.html { redirect_to '/', notice: 'User registered successfully!' }
          end
        else
          respond_to do |format|
            format.html { render :new }
            format.json { render json: @user.errors, status: :unprocessable_entity }
          end
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
          :remember_me,
          :username,
        ]
      end
    end
  end
  