# frozen_string_literal: true

# app/controllers/home_controller.rb
class HomeController < ApplicationController
  include HomeHelper

  def homepage
    respond_to do |format|
      format.html
      format.json { render json: homepage_data }
    end
  end

  def shuffle_recommendations
    unless SiteSetting.enable_shuffle_recommendations
      render json: { error: "Shuffle recommendations is disabled" }, status: :forbidden
      return
    end

    recommendations = load_shuffle_recommendations
    Rails.logger.info("Shuffle recommendations: #{recommendations}")
    render json: recommendations, root: false
  end
end
