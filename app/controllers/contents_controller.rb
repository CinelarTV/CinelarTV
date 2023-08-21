# frozen_string_literal: true

# app/controllers/contents_controller.rb
class ContentsController < ApplicationController

  # This is the controller for the user-side view, Management are in Admin Controller

  def search
    query = params[:q] || params[:query]
    # If the query is empty, return an error
    if query.blank?
        render json: {
            error: "Query is required"
        }, status: :unprocessable_entity
        return
    end

    
    
    @contents = Content.search(params[:q] || params[:query])
    render json: {
        data: @contents.as_json(only: [:id, :title, :description, :image, :type]),
    }
  end
end