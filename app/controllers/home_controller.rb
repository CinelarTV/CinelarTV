# frozen_string_literal: true

# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def homepage
    @homepage_data = Content.homepage_data
    respond_to do |format|
      format.html
      format.json { render json: @homepage_data }
    end
  end
end
