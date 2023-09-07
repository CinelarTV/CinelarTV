# frozen_string_literal: true

# app/controllers/contents_controller.rb
class ContentsController < ApplicationController

  # This is the controller for the user-side view, Management are in Admin Controller

  def search
    query = params[:q] || params[:query]
    # If the query is empty, return an error
    if query.blank?
      respond_to do |format|
        format.html
        format.json {
          render json: {
            errors: [
              "Query is required",
            ],
            error_type: "query_required",
          }
        }
      end
      return
    end

    @contents = Content.search(params[:q] || params[:query])
    respond_to do |format|
      format.html
      format.json {
        render json: {
                 data: @contents.as_json(only: %i[id title description]),
               }
      }
    end
  end

  def show
    @content = Content.find_by(id: params[:id])

    if @content
      @is_liked = current_profile&.liked_contents&.include?(@content)
      @seasons = @content.seasons.order(position: :asc)

      @data = {
        content: @content.as_json(except: %i[created_at updated_at]),
        liked: @is_liked,
      }

      @data[:content][:seasons] = @seasons.map do |s|
        @episode_list = s.episodes.order(position: :asc)
        {
          id: s.id,
          title: s.title,
          description: s.description,
          position: s.position,
          episodes: @episode_list.map do |e|
            {
              id: e.id,
              title: e.title,
              description: e.description,
              position: e.position,
            }
          end,

        }
      end if @seasons.present?

      respond_to do |format|
        format.html
        format.json {
          render json: @data
        }
      end
    else
      respond_to do |format|
        format.html
        format.json { head :not_found }
      end
    end
  end
end
