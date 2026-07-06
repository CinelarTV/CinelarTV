# frozen_string_literal: true

module Admin
  class ContentsController < Admin::BaseController
    before_action :set_content, only: [:show, :analytics, :update, :destroy, :reorder_seasons, :create_season, :sync_categories_from_tmdb, :find_seasons_from_tmdb, :sync_cast_from_tmdb, :remove_cast_member, :add_cast_member]
    before_action :set_season, only: [:create_episode, :episode_list, :find_episodes_from_tmdb, :reorder_episodes, :update_season, :delete_season]
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

    def find_seasons_from_tmdb
      return render_error("TMDB API Key is not set") if SiteSetting.tmdb_api_key.blank?
      return render_error("Content does not have a TMDB ID") if @content.tmdb_id.blank?

      configure_tmdb_api

      api_key = SiteSetting.tmdb_api_key.strip
      language = SiteSetting.default_locale

      cache_key = ["tmdb", "tv", @content.tmdb_id, "detail"].join(":")
      tmdb_data = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        url = "https://api.themoviedb.org/3/tv/#{@content.tmdb_id}?api_key=#{api_key}&language=#{language}"
        response = HTTParty.get(url)
        response.parsed_response
      end

      seasons = (tmdb_data["seasons"] || []).reject { |s| s["season_number"].to_i == 0 }

      existing_tmdb_ids = @content.seasons.where.not(tmdb_id: nil).pluck(:tmdb_id)

      mapped_seasons = seasons.map do |s|
        {
          tmdb_id: s["id"],
          title: s["name"],
          description: s["overview"],
          thumbnail: s["poster_path"] ? "tmdb://#{s['poster_path'].sub(%r{^/}, '')}" : nil,
          air_date: s["air_date"],
          episode_count: s["episode_count"],
          season_number: s["season_number"]
        }
      end.reject { |s| existing_tmdb_ids.include?(s[:tmdb_id]) }

      render json: { data: { seasons: mapped_seasons } }
    rescue StandardError => e
      render_error("Error fetching seasons: #{e.message}")
    end

    def create
      @content = Content.new(content_params)
      @content.available = false
      @content.save!

      ActiveRecord::Base.transaction do
        handle_uploaded_images

        # Auto-assign categories from TMDB if enabled and category_ids not provided manually
        if SiteSetting.enable_category_auto_assignment && params[:tmdb_genre_ids].present? && content_params[:category_ids].blank?
          assign_categories_from_tmdb(params[:tmdb_genre_ids])
        end

        # Auto-assign tmdb_id if provided and not set manually
        if params[:tmdb_id].present? && content_params[:tmdb_id].blank?
          @content.tmdb_id = params[:tmdb_id]
        end

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
      analytics = @content.content_analytic
      recent_sessions = @content.watch_sessions
        .includes(:profile)
        .order(started_at: :desc)
        .limit(20)

      daily_watch_time = @content.watch_sessions
        .where("started_at >= ?", 30.days.ago)
        .group("DATE(started_at)")
        .sum(:duration_watched)
        .transform_values { |seconds| (seconds / 3600.0).round(2) }

      render json: {
        data: {
          content: @content.as_json.merge(like_count: @content.liking_profiles.count),
          analytics: analytics&.as_json || {
            total_views: 0,
            total_seconds_watched: 0,
            unique_profiles: 0,
            completion_rate: 0.0,
            avg_watch_percentage: 0.0,
            last_watched_at: nil
          },
          daily_watch_time: daily_watch_time.map { |date, hours| { x: date.to_s, y: hours } },
          recent_sessions: recent_sessions.map do |session|
            {
              id: session.id,
              profile_name: session.profile&.username,
              started_at: session.started_at,
              ended_at: session.ended_at,
              duration_watched: session.duration_watched,
              total_duration: session.total_duration,
              watch_percentage: session.watch_percentage,
              completed: session.completed,
              country_code: session.country_code
            }
          end
        }
      }
    end

    def create_season
      @season = @content.seasons.new(season_params)
      @season.position = @content.seasons.maximum(:position).to_i + 1

      if @season.save
        render json: { season: @season }, status: :created
      else
        render json: { errors: @season.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update_season
      if @season.update(season_params)
        render json: { season: @season }, status: :ok
      else
        render json: { errors: @season.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete_season
      @season.destroy
      render json: { message: "Temporada eliminada con éxito" }, status: :ok
    end

    def create_episode
      @episode = @season.episodes.new(episode_params)
      @episode.position = @season.episodes.maximum(:position).to_i + 1

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

    def find_episodes_from_tmdb
      return render_error("TMDB API Key is not set") if SiteSetting.tmdb_api_key.blank?

      configure_tmdb_api

      tmdb_id = params[:tmdb_id].presence || @content.tmdb_id
      return render_error("No TMDB ID available") if tmdb_id.blank?

      api_key = SiteSetting.tmdb_api_key.strip
      language = SiteSetting.default_locale

      if params[:season_number].present?
        season_number = params[:season_number].to_i
        cache_key = ["tmdb", "tv", tmdb_id, "season", season_number].join(":")
        tmdb_data = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
          url = "https://api.themoviedb.org/3/tv/#{tmdb_id}/season/#{season_number}?api_key=#{api_key}&language=#{language}"
          response = HTTParty.get(url)
          response.parsed_response
        end
        episodes = tmdb_data["episodes"] || []
      else
        all_episodes = []
        cache_key = ["tmdb", "tv", tmdb_id, "all_seasons"].join(":")
        tmdb_data = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
          url = "https://api.themoviedb.org/3/tv/#{tmdb_id}?api_key=#{api_key}&language=#{language}"
          response = HTTParty.get(url)
          response.parsed_response
        end
        season_count = tmdb_data["number_of_seasons"] || 0

        (1..season_count).each do |sn|
          season_cache_key = ["tmdb", "tv", tmdb_id, "season", sn].join(":")
          season_data = Rails.cache.fetch(season_cache_key, expires_in: 10.minutes) do
            url = "https://api.themoviedb.org/3/tv/#{tmdb_id}/season/#{sn}?api_key=#{api_key}&language=#{language}"
            response = HTTParty.get(url)
            response.parsed_response
          end
          all_episodes.concat(season_data["episodes"] || [])
        end
        episodes = all_episodes
      end

      mapped_episodes = episodes.map do |ep|
        {
          tmdb_id: ep["id"],
          title: ep["name"],
          description: ep["overview"],
          thumbnail: ep["still_path"] ? "tmdb://#{ep['still_path'].sub(%r{^/}, '')}" : nil,
          air_date: ep["air_date"],
          episode_number: ep["episode_number"],
          season_number: ep["season_number"]
        }
      end

      existing_tmdb_ids = Episode.joins(:season).where(seasons: { content_id: @content.id }).where.not(tmdb_id: nil).pluck(:tmdb_id)
      mapped_episodes.reject! { |ep| existing_tmdb_ids.include?(ep[:tmdb_id]) }

      render json: { data: { episodes: mapped_episodes } }
    rescue StandardError => e
      render_error("Error fetching episodes: #{e.message}")
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
      thumb = params.dig(:episode, :thumbnail)
      process_episode_thumbnail(thumb) if thumb.present?
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

    def sync_categories_from_tmdb
      return render json: { error: "TMDB API Key is not set" }, status: :unprocessable_entity if SiteSetting.tmdb_api_key.blank?
      return render json: { error: "Content does not have a TMDB ID" }, status: :unprocessable_entity if @content.tmdb_id.blank?
      return render json: { error: "Category auto-assignment is not enabled" }, status: :unprocessable_entity unless SiteSetting.enable_category_auto_assignment

      configure_tmdb_api
      
      # Fetch content from TMDB using tmdb_id
      tmdb_data = if @content.content_type == "MOVIE"
        Tmdb::Movie.detail(@content.tmdb_id)
      elsif @content.content_type == "TVSHOW"
        Tmdb::TV.detail(@content.tmdb_id)
      else
        return render json: { error: "Unsupported content type" }, status: :unprocessable_entity
      end

      genre_ids = tmdb_data["genres"]&.map { |g| g["id"] } || []
      
      if genre_ids.empty?
        return render json: { message: "No genres found in TMDB for this content" }, status: :ok
      end

      # Map TMDB genre IDs to category IDs
      categories_by_tmdb_id = Category.where.not(tmdb_id: nil).pluck(:tmdb_id, :id).to_h
      category_ids = genre_ids.map { |tmdb_id| categories_by_tmdb_id[tmdb_id] }.compact

      if category_ids.empty?
        return render json: { message: "No matching categories found for TMDB genres" }, status: :ok
      end

      # Assign categories to content
      @content.category_ids = category_ids
      @content.save!

      render json: { 
        message: "Categories synchronized successfully", 
        assigned_count: category_ids.count,
        category_ids: category_ids 
      }, status: :ok
    rescue Tmdb::Error => e
      render json: { error: "TMDB API error: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: "An error occurred: #{e.message}" }, status: :unprocessable_entity
    end

    def sync_cast_from_tmdb
      return render json: { error: "TMDB API Key is not set" }, status: :unprocessable_entity if SiteSetting.tmdb_api_key.blank?
      return render json: { error: "Content does not have a TMDB ID" }, status: :unprocessable_entity if @content.tmdb_id.blank?

      configure_tmdb_api

      tmdb_cast = if @content.content_type == "MOVIE"
                    Tmdb::Movie.cast(@content.tmdb_id)
                  elsif @content.content_type == "TVSHOW"
                    Tmdb::TV.cast(@content.tmdb_id)
                  else
                    return render json: { error: "Unsupported content type" }, status: :unprocessable_entity
                  end

      if tmdb_cast.blank?
        return render json: { message: "No cast found in TMDB", assigned_count: 0 }, status: :ok
      end

      added = 0
      tmdb_cast.each do |person_data|
        next if person_data.id.blank?

        person = Person.find_or_initialize_by(tmdb_id: person_data.id)
        if person.new_record?
          person.name = person_data.name || "Unknown"
          person.profile_path = person_data.profile_path
          person.known_for_department = person_data.known_for_department || "Acting"
          person.save!
        end

        cast_member = CastMember.find_or_initialize_by(content: @content, person: person)
        cast_member.character_name = person_data.character
        cast_member.order = person_data.order || 999
        cast_member.save!
        added += 1
      end

      render json: {
        message: "Cast synchronized successfully",
        assigned_count: added
      }, status: :ok
    rescue Tmdb::Error => e
      render json: { error: "TMDB API error: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: "An error occurred: #{e.message}" }, status: :unprocessable_entity
    end

    def remove_cast_member
      cast_member = @content.cast_members.find(params[:cast_member_id])
      cast_member.destroy
      render json: { message: "Cast member removed" }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Cast member not found" }, status: :not_found
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

    def map_tmdb_genres_to_categories(search_data)
      return {} unless SiteSetting.enable_category_auto_assignment

      # Get all categories with tmdb_id
      categories_by_tmdb_id = Category.where.not(tmdb_id: nil).pluck(:tmdb_id, :id).to_h

      mapping = {}
      search_data.each do |item|
        genre_ids = item["genre_ids"] || []
        category_ids = genre_ids.map { |tmdb_id| categories_by_tmdb_id[tmdb_id.to_i] }.compact
        mapping[item["id"]] = category_ids if category_ids.any?
      end

      mapping
    end

    def assign_categories_from_tmdb(tmdb_genre_ids)
      categories_by_tmdb_id = Category.where.not(tmdb_id: nil).pluck(:tmdb_id, :id).to_h
      category_ids = tmdb_genre_ids.map { |tmdb_id| categories_by_tmdb_id[tmdb_id.to_i] }.compact
      @content.category_ids = category_ids if category_ids.any?
    end

    def handle_uploaded_images
      process_image(:banner) if params[:content][:banner].present?
      process_image(:cover) if params[:content][:cover].present?
      @content.save
    end

    def process_image(type)
      image_value = @content.send(type)

      if image_value&.starts_with?("tmdb://")
        download_tmdb_image(type, image_value)
      else
        # Save uploaded file to temp location and enqueue Sidekiq job
        temp_file = save_temp_file(params[:content][type])
        ImageProcessingJob.perform_async("Content", @content.id, type.to_s, temp_file)
      end
    end

    def download_tmdb_image(type, image_value)
      tmdb_id = image_value.sub("tmdb://", "")
      url = "https://image.tmdb.org/t/p/original/#{tmdb_id}"

      # Download to temp file
      temp_file = download_to_temp_file(url)
      ImageProcessingJob.perform_async("Content", @content.id, type.to_s, temp_file)
    end

    def save_temp_file(uploaded_file)
      temp_dir = Rails.root.join("tmp", "uploads")
      FileUtils.mkdir_p(temp_dir)
      
      temp_file = File.join(temp_dir, "#{SecureRandom.uuid}_#{uploaded_file.original_filename}")
      File.open(temp_file, "wb") do |f|
        f.write(uploaded_file.read)
      end
      
      temp_file
    end

    def download_to_temp_file(url)
      temp_dir = Rails.root.join("tmp", "uploads")
      FileUtils.mkdir_p(temp_dir)

      ext = File.extname(URI.parse(url).path).delete(".")
      ext = "jpg" if ext.blank?

      temp_file = File.join(temp_dir, "#{SecureRandom.uuid}_downloaded_image.#{ext}")
      URI.open(url) do |downloaded_file|
        File.open(temp_file, "wb") do |f|
          f.write(downloaded_file.read)
        end
      end

      temp_file
    end

    def process_episode_thumbnail(thumb_param)
      temp_file = save_temp_file(thumb_param)
      ImageProcessingJob.perform_async("Episode", @episode.id, "thumbnail", temp_file)
    end

    def reorder_records(relation, order_array)
      ids = Array(order_array).map(&:to_s).reject(&:blank?).uniq
      return if ids.empty?

      quoted_ids = ids.map { |id| relation.connection.quote(id) }
      case_statement = quoted_ids.each_with_index.map { |id, index| "WHEN #{id} THEN #{index}" }.join(" ")

      relation.where(id: ids).update_all("position = CASE id::text #{case_statement} END")
    end

    def serialize_content(content)
      content_data = content.as_json

      # Include categories
      content_data[:categories] = content.categories.map { |c| { id: c.id, name: c.name } }
      content_data[:category_ids] = content.category_ids

      if content.content_type == "TVSHOW"
        seasons_data = content.seasons.order(position: :asc)
        content_data[:seasons] = seasons_data.map do |s|
          { id: s.id, title: s.title, description: s.description, position: s.position, tmdb_id: s.tmdb_id, episodes_count: s.episodes.count }
        end
      end

      if content.content_type == "MOVIE" && content.video_sources.content_sources.present?
        content_data[:video_sources] = content.video_sources.content_sources.map do |vs|
          { id: vs.id, url: vs.url, quality: vs.quality, storage_location: vs.storage_location }
        end
      end

      content_data[:trailer_video_sources] = content.video_sources.trailers.map do |vs|
        { id: vs.id, url: vs.url, quality: vs.quality, format: vs.format, storage_location: vs.storage_location }
      end

      content_data[:cast_members] = content.cast_members.includes(:person).ordered.map do |cm|
        {
          id: cm.id,
          character_name: cm.character_name,
          order: cm.order,
          person: cm.person&.as_json
        }
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
      params.require(:content).permit(:title, :description, :banner, :cover, :content_type, :year, :available, :premium, :tmdb_id, :trailer_url,
                                      :scheduled_launch_at, category_ids: [])
    end

    def season_params
      params.require(:season).permit(:title, :description, :tmdb_id)
    end

    def episode_params
      params.require(:episode).permit(:title, :description, :thumbnail, :duration, :position, :premium, :tmdb_id)
    end
  end
end