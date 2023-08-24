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
end
