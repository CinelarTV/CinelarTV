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
    
    def update
      @profile = current_user.profiles.find(params[:id])
        if @profile.update(profile_params)
            render json: { message: 'Profile updated successfully', status: :ok}
            else
            render json: { error: @profile.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end
    end
    
    def destroy
      @profile = current_user.profiles.find(params[:id])
      # Don't allow the user to delete the OWNER profile
        if @profile.profile_type == 'OWNER'
          render json: { error: 'You cannot delete the OWNER profile' }, status: :unprocessable_entity
        else
          @profile.destroy
            render json: { message: 'Profile deleted successfully', status: :ok }
        end


    end
    
    private
    
    def profile_params
        # Solo aceptar que profile_type sea NORMAL o KIDS, ya que OWNER solo debe existir una vez
        params.require(:profile).permit(:name, :avatar_id, :profile_type).tap do |whitelisted|
            whitelisted[:profile_type] = params[:profile][:profile_type] if params[:profile][:profile_type].in? ['NORMAL', 'KIDS']
        end
    end
  end
  