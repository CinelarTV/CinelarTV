# frozen_string_literal: true

module Admin
  class ContentsController < Admin::BaseController
    before_action :set_content, only: [:show, :analytics, :update, :destroy, :reorder_seasons, :create_season]
    before_action :set_season, only: [:create_episode, :episode_list, :reorder_episodes]
    before_action :set_episode, only: [:edit_episode, :update_episode, :delete_episode]

    def find_recommended_metadata
      return render_error("TMDB API Key is not set") if SiteSetting.tmdb_api_key.blank?
      return render_error("Title is required") if params[:title].blank?

      configure_tmdb_api
      search_data = fetch_tmdb_data(params[:title])

      render json: { data: search_data, config: @config.as_json }
    rescue Tmdb::Error => e
      render_error("Error occurred: #{e.message}")
    rescue StandardError => e
      render_error("An error occurred: #{e.message}")
    end

    def create
      @content = Content.new(content_params)
      @content.available = false

      ActiveRecord::Base.transaction do
        handle_uploaded_images
        @content.save!
        render json: { message: "Content created successfully", status: :ok }
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def show
      respond_to do |format|
        format.html
        format.json { render json: { data: serialize_content(@content) } }
      end
    end

    def analytics
      render json: {
        data: {
          content: @content.as_json.merge(like_count: @content.liking_profiles.count)
        }
      }
    end

    def create_season
      @season = @content.seasons.new(season_params)

      if @season.save
        render json: { season: @season }, status: :created
      else
        render json: { errors: @season.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def create_episode
      @episode = @season.episodes.new(episode_params)

      if @episode.save
        render json: { episode: @episode }, status: :created
      else
        render json: { errors: @episode.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def episode_list
      @episodes = @season.episodes.order(position: :asc)

      respond_to do |format|
        format.html
        format.json { render json: { data: { episodes: serialize_episodes(@episodes) } } }
      end
    end

    def reorder_episodes
      return head :bad_request unless params[:episode_order].present?

      reorder_records(@season.episodes, params[:episode_order])
      head :ok
    end

    def edit_episode
      respond_to do |format|
        format.html
        format.json do
          render json: {
            data: {
              episode: @episode.as_json.merge(
                thumbnail: @episode.thumbnail || @content.banner,
                video_sources: @episode.video_sources.as_json(only: %i[id url quality format storage_location status]),
                segments: @episode.segments.as_json(only: %i[id segment_type start_time end_time])
              )
            }
          }
        end
      end
    end

    def reorder_seasons
      return head :bad_request unless params[:season_order].present?

      reorder_records(@content.seasons, params[:season_order])
      render json: { message: "Temporadas reordenadas con éxito", status: :ok }
    end

    def delete_episode
      @episode.destroy
      render json: { message: "Episode deleted successfully", status: :ok }
    end

    def update_episode
      process_episode_thumbnail if params[:thumbnail].present?
      @episode.update(episode_params)
      render json: { message: "Episode updated successfully", status: :ok }
    end

    def update
      ActiveRecord::Base.transaction do
        handle_uploaded_images
        @content.update!(content_params.except(:banner, :cover))
        render json: { message: "Content updated successfully", status: :ok }
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    def destroy
      @content.destroy
      render json: { message: "Content deleted successfully", status: :ok }
    end

    def index
      @contents = Content.includes(:seasons, :video_sources).all
      respond_to do |format|
        format.html
        format.json { render json: { data: @contents.as_json } }
      end
    end

    private

    def set_content
      @content = Content.includes(:seasons, :video_sources).find(params[:id])
    end

    def set_season
      @season = Season.find(params[:season_id])
      @content = @season.content
    end

    def set_episode
      @episode = Episode.find(params[:episode_id])
      @season = @episode.season
      @content = @season.content
    end

    def configure_tmdb_api
      api_key = SiteSetting.tmdb_api_key.strip
      Tmdb::Api.key(api_key)
      Tmdb::Api.language(SiteSetting.default_locale)
      Rails.logger.info("Using TMDB API Key: #{api_key}")
    end

    def fetch_tmdb_data(title)
      normalized_title = title.to_s.strip
      cache_key = ["tmdb", "search", "multi", SiteSetting.default_locale, normalized_title.downcase].join(":")

      Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        Tmdb::Search.multi(normalized_title).table
      end
    end

    def handle_uploaded_images
      process_image(:banner) if params[:content][:banner].present?
      process_image(:cover) if params[:content][:cover].present?
      @content.save
    end

    def process_image(type)
      image_value = @content.send(type)
      uploader = ContentImageUploader.new(type: type)

      if image_value&.starts_with?("tmdb://")
        download_tmdb_image(uploader, image_value)
      else
        uploader.store!(params[:content][type])
      end

      @content.send("#{type}=", uploader.url)
      Rails.logger.info("#{type.to_s.capitalize} URL: #{uploader.url}")
    end

    def download_tmdb_image(uploader, image_value)
      tmdb_id = image_value.sub("tmdb://", "")
      url = "https://image.tmdb.org/t/p/original/#{tmdb_id}"
      uploader.download!(url)
      uploader.store!
    end

    def process_episode_thumbnail
      uploader = ContentImageUploader.new(type: :episode_thumbnail)
      uploader.store!(params[:thumbnail])
      @episode.thumbnail = uploader.url
    end

    def reorder_records(relation, order_array)
      pairs = order_array.each_with_index.map { |id, index| [id.to_i, index] }
      ids = pairs.map(&:first)
      case_statement = pairs.map { |id, index| "WHEN #{id} THEN #{index}" }.join(" ")

      relation.where(id: ids).update_all("position = CASE id #{case_statement} END")
    end

    def serialize_content(content)
      content_data = content.as_json

      if content.content_type == "TVSHOW"
        seasons_data = content.seasons.order(position: :asc)
        content_data[:seasons] = seasons_data.map do |s|
          { id: s.id, title: s.title, description: s.description, position: s.position, episodes_count: s.episodes.count }
        end
      end

      if content.content_type == "MOVIE" && content.video_sources.present?
        content_data[:video_sources] = content.video_sources.map do |vs|
          { id: vs.id, url: vs.url, quality: vs.quality, storage_location: vs.storage_location }
        end
      end

      content_data
    end

    def serialize_episodes(episodes)
      episodes.map do |e|
        {
          id: e.id,
          title: e.title,
          description: e.description,
          thumbnail: e.thumbnail || @content.banner,
          position: e.position
        }
      end
    end

    def render_error(message)
      render json: { error: message }, status: :unprocessable_entity
    end

    def content_params
      params.require(:content).permit(:title, :description, :banner, :cover, :content_type, :year, :available, :premium,
                                      category_ids: [])
    end

    def season_params
      params.require(:season).permit(:title, :description)
    end

    def episode_params
      params.permit(:title, :description, :duration, :position, :premium)
    end
  end
end