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

      # Get the TMDB API Key from the Site Settings
      api_key = SiteSetting.tmdb_api_key.strip
      # Initialize the TMDB API
      Tmdb::Api.key(api_key)

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

    def create
      @content = Content.new(content_params)
      handle_uploaded_images

      if @content.save
        render json: { message: "Content created successfully", status: :ok }
      else
        render json: { errors: @content.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def show
      @content = Content.includes(:seasons, :video_sources).find(params[:id])
      seasons_data = @content.seasons.order(position: :asc) if @content.content_type == "TVSHOW"

      respond_to do |format|
        format.html
        format.json do
          content_data = @content.as_json
          content_data[:seasons] = seasons_data.map do |s|
            { id: s.id, title: s.title, description: s.description, position: s.position }
          end if seasons_data
          content_data[:video_sources] = @content.video_sources.map do |vs|
            { id: vs.id, url: vs.url, quality: vs.quality, storage_location: vs.storage_location }
          end if @content.video_sources && @content.content_type == "MOVIE"
          # Episodes are not included in the content data because they are loaded separately

          render json: { data: content_data }
        end
      end
    end

    def analytics
      @content = Content.find(params[:id])

      # Content doesn't have analytics, so we need to find manually

      # Like count
      @like_count = @content.liking_profiles.count

      respond_to do |format|
        format.html
        format.json do
          render json: {
            data: {
              content: @content.as_json.merge({
                like_count: @like_count,
              }),
            },
          }
        end
      end
    end

    def create_season
      @content = Content.find(params[:content_id])
      @season = @content.seasons.new(season_params)

      if @season.save
        render json: { season: @season }, status: :created
      else
        render json: { errors: @season.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def create_episode
      @season = Season.find(params[:season_id])
      @episode = @season.episodes.new(episode_params)

      if @episode.save
        render json: { episode: @episode }, status: :created
      else
        render json: { errors: @episode.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def episode_list
      # Find season based on the season_id (And check if it belongs to the content)
      @season = Season.find(params[:season_id])
      @content = @season.content

      if @content
        @episodes = @season.episodes.order(position: :asc)

        respond_to do |format|
          format.html
          format.json do
            render json: {
              data: {
                episodes: @episodes.map do |e|
                  { id: e.id, title: e.title, description: e.description,
                    thumbnail: e.thumbnail || @content.banner, position: e.position }
                end,
              },
            }
          end
        end
      else
        respond_to do |format|
          format.html
          format.json { head :not_found }
        end
      end
    end

    def reorder_episodes
      @season = Season.find(params[:season_id])
      episode_order = params[:episode_order]

      return unless episode_order.present?

      episode_order.each_with_index do |episode_id, index|
        episode = @season.episodes.find(episode_id)
        episode.update(position: index)
      end
    end

    def edit_episode
      @episode = Episode.find(params[:episode_id])
      @season = @episode.season
      @content = @season.content

      respond_to do |format|
        format.html
        format.json do
          render json: {
            data: {
              episode: @episode.as_json.merge({
                thumbnail: @episode.thumbnail || @content.banner,
              }),
            },
          }
        end
      end
    end

    def reorder_seasons
      @content = Content.find(params[:id])
      season_order = params[:season_order]

      if season_order.present?
        season_order.each_with_index do |season_id, index|
          season = @content.seasons.find(season_id)
          season.update(position: index)
        end
      end

      render json: { message: "Temporadas reordenadas con éxito", status: :ok }
    end

    def delete_episode
      @episode = Episode.find(params[:episode_id])
      @episode.destroy
      render json: { message: "Episode deleted successfully", status: :ok }
    end

    def update_episode
      @episode = Episode.find(params[:episode_id])
      @episode.update(episode_params)
      render json: { message: "Episode updated successfully", status: :ok }
    end


    def update
      @content = Content.find(params[:id])

      # Await the uploaded images
      handle_uploaded_images

      @content.assign_attributes(content_params.except(:banner, :cover))
      # Ignore banner and cover because they are processed above

      # Series can't have an url
      @content.url = nil if @content.content_type == "TVSHOW" && @content.url?

      if @content.save
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

    def handle_uploaded_images
      # Process banner image
      Rails.logger.info("Banner: #{params[:content][:banner]}")

      if params[:content][:banner].present? || !params[:content][:banner].nil? || !params[:content][:banner].blank?
        if @content.banner&.starts_with?("tmdb://")
          # Process TMDB reference here
          tmdb_id = @content.banner.sub("tmdb://", "")
          banner_url = "https://image.tmdb.org/t/p/original/#{tmdb_id}"
          uploader = ContentImageUploader.new
          uploader.download!(banner_url)
          @content.banner = uploader.url
        else
          # Process uploaded banner image here
          banner_uploader = ContentImageUploader.new
          banner_uploader.store!(params[:content][:banner])
          @content.banner = banner_uploader.url
          Rails.logger.info("Banner URL: #{banner_uploader.url}")
        end
      end

      # Process cover image
      if params[:content][:cover].present? || !params[:content][:cover].nil? || !params[:content][:cover].blank?
        if @content.cover&.starts_with?("tmdb://")
          # Process TMDB reference here
          tmdb_id = @content.cover.sub("tmdb://", "")
          cover_url = "https://image.tmdb.org/t/p/original/#{tmdb_id}"
          uploader = ContentImageUploader.new
          uploader.download!(cover_url)
          @content.cover = uploader.url
        else
          # Process uploaded cover image here
          cover_uploader = ContentImageUploader.new
          cover_uploader.store!(params[:content][:cover])
          @content.cover = cover_uploader.url
          Rails.logger.info("Cover URL: #{cover_uploader.url}")
        end
      end

      @content.save
    end

    private

    def content_params
      params.require(:content).permit(:title, :description, :banner, :cover, :content_type, :url, :year, :available,
                                      category_ids: [])
    end

    def season_params
      params.require(:season).permit(:title, :description)
    end

    def episode_params
      params.require(:episode).permit(:title, :description, :url, :duration, :position)
    end

    def set_content
      @content = Content.find(params[:id])
    end
  end
end
