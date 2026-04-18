# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_user! # Ensure the user is authenticated

  def index
    @profiles = current_user.profiles
  end

  def show
    @profile = current_user.profiles.find(params[:id])
    render json: @profile
  end

  def edit
    @profile = current_user.profiles.find(params[:id])
  end

  def create
    @profile = current_user.profiles.new(profile_params)
    # Set the profile type to OWNER if it's the first profile
    @profile.profile_type = "OWNER" if current_user.profiles.count.zero?
    # Validate avatar_id against allowed list
    if profile_params[:avatar_id].present? && !Profile.valid_avatar_id?(profile_params[:avatar_id])
      render json: { errors: ["Invalid avatar"] }, status: :unprocessable_entity and return
    end
    if @profile.save
      broadcast_profile_update(current_user, {})
      render json: {
        message: "Profile created successfully",
        status: :ok,
        profile: {
          id: @profile.id,
          name: @profile.name,
          avatar_id: @profile.avatar_id,
          profile_type: @profile.profile_type
        }
      }
    else
      render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @profile = current_user.profiles.find(params[:id])
    if params[:profile] && params[:profile][:avatar_id].present? && !Profile.valid_avatar_id?(params[:profile][:avatar_id])
      render json: { error: "Invalid avatar" }, status: :unprocessable_entity and return
    end

    if @profile.update(profile_params)
      broadcast_profile_update(current_user, {})
      render json: {
        message: "Profile updated successfully",
        status: :ok,
        profile: {
          id: @profile.id,
          name: @profile.name,
          avatar_id: @profile.avatar_id,
          profile_type: @profile.profile_type
        }
      }
    else
      render json: { error: @profile.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    @profile = current_user.profiles.find(params[:id])
    # Don't allow the user to delete the OWNER profile
    if @profile.profile_type == "OWNER"
      render json: { error: "You cannot delete the OWNER profile" }, status: :unprocessable_entity
    else
      @profile.destroy
      broadcast_profile_update(current_user, {})
      render json: { message: "Profile deleted successfully", status: :ok }
    end
  end

  def default_avatars
    render json: Profile.default_avatars
  end

  private

  def profile_params
    # Solo aceptar que profile_type sea NORMAL o KIDS, ya que OWNER solo debe existir una vez
    params.require(:profile).permit(:name, :avatar_id, :profile_type).tap do |whitelisted|
      whitelisted[:profile_type] = params[:profile][:profile_type] if params[:profile][:profile_type].in? %w[NORMAL
                                                                                                             KIDS]
    end
  end
end
