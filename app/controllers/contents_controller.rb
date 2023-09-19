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
        format.json do
          render json: {
            errors: [
              "Query is required",
            ],
            error_type: "query_required",
          }
        end
      end
      return
    end

    @contents = Content.search(params[:q] || params[:query])
    respond_to do |format|
      format.html
      format.json do
        render json: {
          data: @contents.as_json(only: %i[id title description banner]),
        }
      end
    end
  end

  def show
    @content = Content.find_by(id: params[:id])

    if @content
      @is_liked = current_profile&.liked_contents&.include?(@content)
      @seasons = @content.seasons.order(position: :asc)
      @related_content = @content.similar_items
      if current_profile && @content.content_type == "SERIES"
        most_recent_watched_episode = ContinueWatching.where(profile: current_profile,
                                                             content: @content).order(updated_at: :desc).not(episode_id: nil).first
      end
      if current_profile && @content.content_type == "MOVIE"
        continue_watching = ContinueWatching.where(profile: current_profile,
                                                   content: @content).order(updated_at: :desc).first
      end
      @data = {
        content: @content.as_json(except: %i[created_at updated_at url]),
        liked: @is_liked,
        related_content: @related_content.as_json(only: %i[id title description banner]),
      }

      if most_recent_watched_episode.present?
        @data[:content][:most_recent_watched_episode] =
          most_recent_watched_episode.as_json(only: %i[episode_id progress
                                                       duration])
      end
      if continue_watching.present?
        @data[:content][:continue_watching] =
          continue_watching.as_json(only: %i[progress duration])
      end
      if @seasons.present?
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
                thumbnail: e.thumbnail || @content.banner,
                position: e.position,
              }
            end,

          }
        end
      end

      respond_to do |format|
        format.html
        format.json do
          render json: @data
        end
      end
    else
      respond_to do |format|
        format.html
        format.json { head :not_found }
      end
    end
  end
end
