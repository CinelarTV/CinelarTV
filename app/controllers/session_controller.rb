# frozen_string_literal: true

class SessionController < ApplicationController
  def current_user_json
    render json: current_user
  end

  def profiles
    # Try to find the user profiles, if fails, return an empty array
    profiles = current_user.profiles rescue []
    render json: profiles
  end

  def select_profile
    if current_user.update(user_params)
      if params[:user][:selected_profile_id].present?
        selected_profile = current_user.profiles.find(params[:user][:selected_profile_id])
        selected_profile.update(user_id: current_user.id)
        session[:current_profile_id] = selected_profile.id
      end
      render json: { message: "Profile selection updated successfully" }
    else
      render json: { error: "Failed to update profile selection" }, status: :unprocessable_entity
    end
  end

  def deassign_profile
    if current_user.update(user_params)
      session[:current_profile_id] = nil
      render json: { message: "Profile deassigned successfully" }
    else
      render json: { error: "Failed to deassign profile" }, status: :unprocessable_entity
    end
  end

  def csrf
    render json: { csrf: form_authenticity_token }
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, profile_attributes: %i[display_name username biography selected_profile_id])
  end
end
