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

    def create 
        @content = Content.new(content_params)
        if @content.save
            render json: { message: "Content created successfully", status: :ok }
        else
            render json: { errors: @content.errors.full_messages }, status: :unprocessable_entity
        end
        end
  end

    def update
        @content = Content.find(params[:id])
        if @content.update(content_params)
            render json: { message: "Content updated successfully", status: :ok }
        else
            render json: { error: @content.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
    end

    def destroy
        @content = Content.find(params[:id])
        @content.destroy
        render json: { message: "Content deleted successfully", status: :ok }
    end

    private

    def content_params
        params.require(:content).permit(:title, :description, :banner, :cover, :type, :url, :year, category_ids: [])
    end

    def set_content
        @content = Content.find(params[:id])
    end

    


end
