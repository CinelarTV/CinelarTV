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
    if current_user.profiles.count == 0
      @profile.profile_type = "OWNER"
    end
    if @profile.save
      render json: { message: "Profile created successfully", status: :ok }
    else
      render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @profile = current_user.profiles.find(params[:id])
    if @profile.update(profile_params)
      render json: { message: "Profile updated successfully", status: :ok }
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
      render json: { message: "Profile deleted successfully", status: :ok }
    end
  end

  def default_avatars
    # List default avatars (Currently is a static list, but in the future we allow the Admin to add more)
    render json: [
      { id: 'coolCat', name: 'Cool Cat', path: '/assets/default/avatars/coolCat.png' },
      { id: 'cuteCat', name: 'Cute Cat', path: '/assets/default/avatars/cuteCat.png' },
      { id: 'dino_boy', name: 'Dino Boy', path: '/assets/default/avatars/dino_boy.png' },
      { id: 'baby_unicorn', name: 'Baby Unicorn', path: '/assets/default/avatars/baby_unicorn.png' },
    ]
  end

  private

  def profile_params
    # Solo aceptar que profile_type sea NORMAL o KIDS, ya que OWNER solo debe existir una vez
    params.require(:profile).permit(:name, :avatar_id, :profile_type).tap do |whitelisted|
      whitelisted[:profile_type] = params[:profile][:profile_type] if params[:profile][:profile_type].in? ["NORMAL", "KIDS"]
    end
  end
  
end
