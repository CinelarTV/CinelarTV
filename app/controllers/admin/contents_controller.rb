# frozen_string_literal: true

module Admin
  class ContentsController < Admin::BaseController
    def find_recommended_metadata
      if SiteSetting.tmdb_api_key.blank?
        render json: { error: "TMDB API Key is not set" }, status: :unprocessable_entity
        return
      end

      if params[:title].blank?
        render json: { error: "Title is required" }, status: :unprocessable_entity
        return
      end

      Tmdb::Api.key(SiteSetting.tmdb_api_key)
      Tmdb::Api.language(SiteSetting.default_locale) 
      @search = Tmdb::Search.multi(params[:title])
      puts @search
      # Render as JSON
        render json: @search.results
    end
  end
end
