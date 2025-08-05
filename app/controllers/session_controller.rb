# frozen_string_literal: true

class SessionController < ApplicationController
  before_action :authenticate_user!, only: %i[current_user_json profiles select_profile deassign_profile]
  def current_user_json
    render json: current_user,
           serializer: CurrentUserSerializer,
           include_profiles: true,
           current_profile_id: session[:current_profile_id]
  end

  def profiles
    # Try to find the user profiles, if fails, return an empty array
    profiles = begin
        current_user.profiles
      rescue StandardError
        []
      end
    render json: profiles
  end

  def select_profile
    if current_user.update(user_params)
      if params[:profile_id].present?
        selected_profile = current_user.profiles.find(params[:profile_id])
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
    params.permit(:email, :password, :password_confirmation,
                 profile_attributes: %i[display_name username biography profile_id])
  end
end
