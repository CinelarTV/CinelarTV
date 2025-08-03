# frozen_string_literal: true

# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  before_action :authenticate_user!

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
end
