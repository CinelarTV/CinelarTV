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
      Rails.logger.info "[RegistrationsController] create called with format: #{request.format}"
      Rails.logger.info "[RegistrationsController] params: #{params.inspect}"

      @user = User.new(sign_up_params)

      if @user.save
        Rails.logger.info "[RegistrationsController] User saved successfully: #{@user.id}"
        respond_to do |format|
          format.json do
            Rails.logger.info "[RegistrationsController] Rendering JSON response"
            render json: { message: "Registration successful. Please check your email to confirm your account.", error_type: "unconfirmed", needs_confirmation: true }, status: :created
          end
          format.html { redirect_to "/", notice: "Registration successful. Please check your email to confirm your account." }
          format.any { render json: { message: "Registration successful. Please check your email to confirm your account.", error_type: "unconfirmed", needs_confirmation: true }, status: :created }
        end
      else
        Rails.logger.info "[RegistrationsController] User save failed: #{@user.errors.full_messages}"
        respond_to do |format|
          format.html { render :new }
          format.json do
            # Normalize errors to a consistent format
            error_messages = @user.errors.full_messages
            render json: {
              error: error_messages.first,
              errors: error_messages,
              message: error_messages.first
            }, status: :unprocessable_entity
          end
          format.any do
            error_messages = @user.errors.full_messages
            render json: {
              error: error_messages.first,
              errors: error_messages,
              message: error_messages.first
            }, status: :unprocessable_entity
          end
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
      %i[
        email
        password
        password_confirmation
        remember_me
        username
      ]
    end
  end
end
