# frozen_string_literal: true

class ExceptionsController < ApplicationController
  # Endpoint to recommend content on 404 not found pages

  def not_found
    raise CinelarTV::NotFound
  end

  def not_found_body
    @contents = Content.where(available: true).order("RANDOM()").limit(10)
    render json: { contents: @contents }
  end
end
