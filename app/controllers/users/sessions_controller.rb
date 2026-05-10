# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    respond_to :json

    # POST /sign_in
    def create
      user = User.find_by(email: params[:user][:email]) || User.find_by(username: params[:user][:email])

      if user && !user.confirmed?
        respond_to do |format|
          format.json { render json: { error: "unconfirmed", message: "You have to confirm your email address before continuing.", needs_confirmation: true }, status: 401 }
        end
        return
      end

      self.resource = warden.authenticate!(auth_options)
      sign_in(resource_name, resource)
      respond_with(resource) do |format|
        format.json { render json: { redirect_url: after_sign_in_path_for(resource) }, status: 200 }
      end
    end
  end
end
