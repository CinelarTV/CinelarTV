# frozen_string_literal: true

class SessionController < ApplicationController
  before_action :authenticate_user_or_doorkeeper!, only: %i[current_user_json profiles select_profile deassign_profile]

  def current_user_json
    render json: current_user_with_doorkeeper,
           serializer: CurrentUserSerializer,
           include_profiles: true,
           current_profile_id: get_current_profile_id
  end

  def profiles
    # Try to find the user profiles, if fails, return an empty array
    profiles = begin
      current_user_with_doorkeeper.profiles
    rescue StandardError
      []
    end
    render json: profiles
  end

  def select_profile
    if current_user_with_doorkeeper.update(user_params)
      if params[:profile_id].present?
        selected_profile = current_user_with_doorkeeper.profiles.find(params[:profile_id])
        selected_profile.update(user_id: current_user_with_doorkeeper.id)
        set_current_profile_id(selected_profile.id)
      end
      render json: { message: "Profile selection updated successfully" }
    else
      render json: { error: "Failed to update profile selection" }, status: :unprocessable_entity
    end
  end

  def deassign_profile
    if current_user_with_doorkeeper.update(user_params)
      set_current_profile_id(nil)
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

  # Authenticate either through Devise session or Doorkeeper token
  def authenticate_user_or_doorkeeper!
    return if current_user.present? # Devise session

    doorkeeper_authorize! # Doorkeeper token
  end

  # Get current user from either Devise or Doorkeeper
  def current_user_with_doorkeeper
    current_user || User.find(doorkeeper_token.resource_owner_id)
  end

  def using_doorkeeper?
    doorkeeper_token.present?
  end

  def get_current_profile_id
    if using_doorkeeper?
      # Para Doorkeeper, usar cache con el token como key
      CinelarTV.cache.read("profile_#{doorkeeper_token.token}")
    else
      # Para sesiones normales
      session[:current_profile_id]
    end
  end

  def set_current_profile_id(profile_id)
    if using_doorkeeper?
      # Para Doorkeeper, guardar en cache por 1 día
      CinelarTV.cache.write("profile_#{doorkeeper_token.token}", profile_id, expires_in: 1.day)
    else
      # Para sesiones normales
      session[:current_profile_id] = profile_id
    end
  end
end
