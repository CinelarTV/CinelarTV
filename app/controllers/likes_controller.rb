# frozen_string_literal: true

# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_profile_selected, only: %i[like unlike toggle_like]

  def like
    @content = Content.find(params[:id])
    if current_profile.liked_contents.include?(@content)
      render json: {
        error: "You already liked this content"
      }, status: :unprocessable_entity
    else
      current_profile.liked_contents << @content
      render json: {
        message: "Content liked successfully"
      }
    end
  end

  def unlike
    @content = Content.find(params[:id])
    if current_profile.liked_contents.include?(@content)
      current_profile.liked_contents.delete(@content)
      render json: {
        message: "Content unliked successfully"
      }
    else
      render json: {
        error: "You didn't like this content"
      }, status: :unprocessable_entity
    end
  end

  # This method can be used in the future to toggle like/unlike with a single endpoint
  # Return 204 No Content on success, and 422 Unprocessable Entity if the content is not found or any other error occurs
  def toggle_like
    @content = Content.find(params[:id])
    if current_profile.liked_contents.include?(@content)
      current_profile.liked_contents.delete(@content)
      head :no_content
    else
      current_profile.liked_contents << @content
      head :no_content
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "Content not found"
    }, status: :not_found
  end

  private

  def require_profile_selected
    return if current_profile.present?

    render json: { error: "missing_profile", message: "Please select a profile to perform this action" }, status: :unprocessable_entity
  end
end
