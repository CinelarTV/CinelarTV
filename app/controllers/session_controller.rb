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
    profile_id = params[:profile_id]

    unless profile_id.present?
      render json: { error: "missing_profile_id", message: "Profile ID is required" }, status: :unprocessable_entity
      return
    end

    selected_profile = current_user_with_doorkeeper.profiles.find_by(id: profile_id)

    unless selected_profile
      render json: { error: "profile_not_found", message: "Profile not found or doesn't belong to you" }, status: :not_found
      return
    end

    set_current_profile_id(selected_profile.id)

    render json: { message: "Profile selection updated successfully" }
  end

  def deassign_profile
    set_current_profile_id(nil)
    render json: { message: "Profile deassigned successfully" }
  end

  def csrf
    render json: { csrf: form_authenticity_token }
  end

  private

  # Authenticate either through Devise session or Doorkeeper token
  def authenticate_user_or_doorkeeper!
    return if current_user.present? # Devise session

    doorkeeper_authorize! # Doorkeeper token
  end

  # Get current user from either Devise or Doorkeeper
  def current_user_with_doorkeeper
    current_user || User.find_by(id: doorkeeper_token.resource_owner_id)
  end

  def using_doorkeeper?
    doorkeeper_token.present?
  end

  def get_current_profile_id
    if using_doorkeeper?
      doorkeeper_token.current_profile_id
    else
      session[:current_profile_id]
    end
  end

  def set_current_profile_id(profile_id)
    if using_doorkeeper?
      doorkeeper_token&.update_column(:current_profile_id, profile_id)
    else
      session[:current_profile_id] = profile_id
    end
  end
end
