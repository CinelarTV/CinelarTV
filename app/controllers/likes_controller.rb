# frozen_string_literal: true

# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_profile_selected, only: %i[like unlike toggle_like]

  def like
    @content = Content.find(params[:id])
    # Remove dislike if it exists (mutual exclusion)
    current_profile.disliked_contents.delete(@content)

    if current_profile.liked_contents.include?(@content)
      current_profile.liked_contents.delete(@content)
    else
      current_profile.liked_contents << @content
    end

    clearLikedCache
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Content not found" }, status: :not_found
  end

  def unlike
    @content = Content.find(params[:id])
    if current_profile.liked_contents.include?(@content)
      current_profile.liked_contents.delete(@content)
      clearLikedCache
      head :no_content
    else
      render json: { error: "You didn't like this content" }, status: :unprocessable_entity
    end
  end

  def toggle_like
    @content = Content.find(params[:id])
    # Remove dislike if it exists (mutual exclusion)
    current_profile.disliked_contents.delete(@content)

    if current_profile.liked_contents.include?(@content)
      current_profile.liked_contents.delete(@content)
    else
      current_profile.liked_contents << @content
    end

    clearLikedCache
    clearDislikedCache
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Content not found" }, status: :not_found
  end

  private

  def require_profile_selected
    return if current_profile.present?

    render json: {
      error: "missing_profile",
      message: "Please select a profile to perform this action"
    }, status: :unprocessable_entity
  end

  def clearLikedCache
    CinelarTV.cache.delete("profile_liked_ids/#{current_profile.id}")
  end

  def clearDislikedCache
    CinelarTV.cache.delete("profile_disliked_ids/#{current_profile.id}")
  end
end
