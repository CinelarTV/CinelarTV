# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    respond_to :json

    # POST /users/password.json
    # Send password reset instructions
    def create
      self.resource = resource_class.find_by(email: resource_params[:email])

      if resource.present?
        resource.send_reset_password_instructions
      end

      # Always return success to prevent email enumeration
      respond_to do |format|
        format.json { render json: { message: "If your email exists in our system, you will receive a password reset link shortly." }, status: :ok }
      end
    end

    # PATCH/PUT /users/password.json
    # Reset password with token
    def update
      self.resource = resource_class.reset_password_by_token(resource_params)

      if resource.errors.empty?
        set_flash_message!(:notice, :updated)
        sign_in(resource_name, resource)
        respond_to do |format|
          format.json { render json: { message: "Your password has been reset successfully." }, status: :ok }
        end
      else
        respond_to do |format|
          format.json { render json: { errors: resource.errors.full_messages, error: resource.errors.full_messages.first }, status: :unprocessable_entity }
        end
      end
    end
  end
end
