# frozen_string_literal: true

module Admin
  class ContentsController < Admin::BaseController
    def find_recommended_metadata
      begin
        if SiteSetting.tmdb_api_key.blank?
          render json: { error: "TMDB API Key is not set" }, status: :unprocessable_entity
          return
        end

        if params[:title].blank?
          render json: { error: "Title is required" }, status: :unprocessable_entity
          return
        end

        # Get the TMDB API Key from the Site Settings
        api_key = SiteSetting.tmdb_api_key.strip
        # Initialize the TMDB API
        tmdb = Tmdb::Api.key(api_key)

        Tmdb::Api.language(SiteSetting.default_locale)

        Rails.logger.info("Using TMDB API Key: #{api_key}")

        @search = Tmdb::Search.multi(params[:title])
        # Render as JSON
        render json: {
                 data: @search.table,
                 config: @config.as_json,
               }
      rescue Tmdb::Error => e
        render json: { error: "Error occurred: #{e.message}" }, status: :unprocessable_entity
      rescue StandardError => e
        render json: { error: "An error occurred: #{e.message}" }, status: :unprocessable_entity
      end
    end

    def create
      @content = Content.new(content_params)

      # Check if banner or cover is a TMDB reference
      if @content.banner&.starts_with?("tmdb://")
        # Process TMDB reference here
        tmdb_id = @content.banner.sub("tmdb://", "")
        # Perform logic to download and store the TMDB image locally using BaseUploader
        banner_url = "https://image.tmdb.org/t/p/w780/#{tmdb_id}"
        uploader = BaseUploader.new
        uploader.download!(banner_url)
        @content.banner = uploader.url
      end

      if @content.cover&.starts_with?("tmdb://")
        # Process TMDB reference here for cover image
        tmdb_id = @content.cover.sub("tmdb://", "")
        # Perform logic to download and store the TMDB image locally using BaseUploader
        cover_url = "https://image.tmdb.org/t/p/w780/#{tmdb_id}"
        uploader = BaseUploader.new
        uploader.download!(cover_url)
        @content.cover = uploader.url
      end

      if @content.save
        render json: { message: "Content created successfully", status: :ok }
      else
        render json: { errors: @content.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def show
      @content = Content.find(params[:id])
      respond_to do |format|
        format.html
        format.json do
          render json: {
                   data: @content.as_json,
                 }
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

    def index
      @contents = Content.all
      respond_to do |format|
        format.html
        format.json do
          render json: {
                   data: @contents.as_json,
                 }
        end
      end
    end

    private

    def content_params
      params.require(:content).permit(:title, :description, :banner, :cover, :content_type, :url, :year, category_ids: [])
    end

    def set_content
      @content = Content.find(params[:id])
    end
  end
end
