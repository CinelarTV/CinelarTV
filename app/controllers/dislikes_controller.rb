# frozen_string_literal: true

class DislikesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_profile_selected

  def dislike
    @content = Content.find(params[:id])
    # Remove like if it exists (mutual exclusion)
    current_profile.liked_contents.delete(@content)

    if current_profile.disliked_contents.include?(@content)
      current_profile.disliked_contents.delete(@content)
    else
      current_profile.disliked_contents << @content
    end

    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Content not found" }, status: :not_found
  end

  def undislike
    @content = Content.find(params[:id])
    if current_profile.disliked_contents.include?(@content)
      current_profile.disliked_contents.delete(@content)
      head :no_content
    else
      render json: { error: "You didn't dislike this content" }, status: :unprocessable_entity
    end
  end

  def toggle_dislike
    @content = Content.find(params[:id])
    # Remove like if it exists (mutual exclusion)
    current_profile.liked_contents.delete(@content)

    if current_profile.disliked_contents.include?(@content)
      current_profile.disliked_contents.delete(@content)
    else
      current_profile.disliked_contents << @content
    end

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
end
