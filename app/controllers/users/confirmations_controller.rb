# frozen_string_literal: true

module Users
  class ConfirmationsController < Devise::ConfirmationsController
    respond_to :json

    # POST /users/confirmation
    # Resend confirmation email
    def create
      self.resource = resource_class.send_confirmation_instructions(resource_params)
      if successfully_sent?(resource)
        respond_to do |format|
          format.json { render json: { message: "Confirmation instructions sent successfully" }, status: :ok }
        end
      else
        respond_to do |format|
          format.json { render json: { error: "Failed to send confirmation instructions" }, status: :unprocessable_entity }
        end
      end
    end

    # GET /users/confirmation?confirmation_token=...
    # Confirm account with token
    def show
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if resource.errors.empty?
        set_flash_message!(:notice, :confirmed)
        respond_to do |format|
          format.json { render json: { message: "Account confirmed successfully" }, status: :ok }
          format.html { redirect_to after_confirmation_path_for(resource_name, resource) }
        end
      else
        respond_to do |format|
          format.json { render json: { error: "Invalid confirmation token" }, status: :unprocessable_entity }
          format.html { respond_with_navigational(resource) { render :new } }
        end
      end
    end

    # GET /users/confirmation/new
    # Show form to request new confirmation (for SPA, returns JSON)
    def new
      self.resource = resource_class.new
      respond_to do |format|
        format.json { render json: { message: "POST to /users/confirmation with user[email] to resend" }, status: :ok }
        format.html { respond_with({}, location: new_user_confirmation_path) }
      end
    end
  end
end
