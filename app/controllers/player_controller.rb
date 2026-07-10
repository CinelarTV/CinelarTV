# frozen_string_literal: true

class PlayerController < ApplicationController
  before_action :authenticate_user!
  before_action :find_content, only: :watch
  before_action :check_content_availability, only: :watch
  before_action :check_subscription, only: :watch

  def watch
    unless @content
      return respond_to do |format|
        format.html { render_content_not_available }
        format.json { render_content_not_available }
      end
    end

    find_episode_and_season if @content.content_type == "TVSHOW"

    profile = current_profile

    unless profile
      return respond_to do |format|
        format.json { render json: { error: "No profile selected" }, status: :unprocessable_entity }
      end
    end
    continue_watching = create_or_find_continue_watching(profile)

    reproduction = Reproduction.new(
      profile_id: profile.id,
      content_id: @content.id,
      played_at: Time.now
    )

    if request.format.json?
      @stream_session_result = StreamSessionManager.start_session(
        current_user,
        device_name: stream_device_name,
        device_type: stream_device_type,
        profile_id: profile&.id,
        requested_session_id: params[:deviceSessionToken].presence || params[:streamSessionToken].presence,
        content_title: @content&.title,
        episode_title: @episode&.title
      )

      if @stream_session_result.limit_reached?
        return respond_to do |format|
          format.html { render template: "application/index", status: :forbidden }
          format.json do
            render json: { error: "STREAM_LIMIT_REACHED", sessions: @stream_session_result.active_sessions },
                   status: :forbidden
          end
        end
      end
    else
      @stream_session_result = StreamSessionManager::Result.new(success: true, skipped: true)
    end

    ip_address = request.headers["CF-Connecting-IP"] || request.remote_ip

    if ip_address.present?
      Rails.logger.info "IP address: #{ip_address}"
      reproduction.set_country_code(ip_address)
    else
      Rails.logger.warn "No IP address available, country code not set"
    end

    begin
      reproduction.save if request.format.json?
    rescue StandardError => e
      Rails.logger.error "Error saving reproduction: #{e.message}"
    end

    create_watch_session(profile, ip_address) if request.format.json?

    respond_to do |format|
      format.html
      format.json { render_json_response(continue_watching) }
    end
  end

  def update_current_progress
    profile = current_profile
    return render json: { error: "No profile" }, status: :unprocessable_entity unless profile

    content_id = params[:id]
    episode_id = params[:episode_id].presence
    progress = params[:progress].to_f
    duration = params[:duration].to_f

    # 1. Guardar solo en Redis
    episode_key = episode_id.presence || 'movie'
    CinelarTV.cache.write("progress/#{profile.id}/#{content_id}/#{episode_key}", {
      progress: progress,
      duration: duration,
      last_watched_at: Time.current
    }, expires_in: 24.hours)

    # 2. Encolar job de sincronización
    SyncProgressJob.perform_async(profile.id, content_id, episode_id, progress, duration)

    # 3. Actualizar la sesión activa (podemos mantener esta parte síncrona si es poco frecuente, 
    # pero para máximo rendimiento también podría ir al job)
    update_watch_session(profile, content_id, episode_id, progress, duration)

    head :no_content
  end

  private

  def find_content
    @content = Content.includes(:video_sources, :segments, seasons: { episodes: :video_sources })
                      .find_by(id: params[:id])
  end

  def check_content_availability
    return if content_available?

    render_content_not_available
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def check_subscription
    # TVSHOW check needs episode to be loaded
    find_episode_and_season if @content.content_type == "TVSHOW"

    is_premium = @content.premium?
    is_premium ||= @episode&.premium? if @content.content_type == "TVSHOW"

    return unless is_premium
    return if current_user.has_role?(:admin) # Admins bypass check
    return if current_user.is_subscribed?

    render_subscription_required
  end

  def find_episode_and_season
    if params[:episode_id]
      @episode = Episode.find_by(id: params[:episode_id])
      @season = @content.seasons.find_by(id: @episode&.season_id)
    else
      @season = @content.seasons.first
      @episode = @season.episodes.first if @season
    end
  end

  def create_or_find_continue_watching(profile)
    return unless profile && @content

    ContinueWatching.find_or_create_by(
      profile_id: profile.id,
      content_id: @content.id,
      episode_id: @episode&.id
    )
  end

  def render_json_response(continue_watching)
    return render_content_not_found unless @content

    data = {
      content: {
        id: @content.id,
        title: @content.title,
        description: @content.description,
        content_type: @content.content_type,
        banner: @content.banner,
      },
      continue_watching: continue_watching&.as_json(except: %i[created_at updated_at profile_id episode_id content_id
                                                               id]),
    }

    if @content.content_type == "MOVIE"
      sources_data = video_sources_data
      data[:sources] = sources_data[:sources]
      data[:content][:segments] = sources_data[:segments]
    elsif @content.content_type == "TVSHOW" && @episode
      sources_data = episode_video_sources_data
      data[:sources] = sources_data[:sources]
      data[:episode] = @episode.as_json(except: %i[created_at updated_at])
      data[:episode][:segments] = sources_data[:segments]
    end
    # Temporada actual con episodios
    data[:season] = @season.as_json(except: %i[created_at updated_at]) if @season
    if @season
      data[:season][:episodes] =
        @season.episodes.order(position: :asc).as_json(only: %i[id title description thumbnail position])
    end

    # Todas las temporadas para navegación entre temporadas
    if @content.content_type == "TVSHOW"
      data[:seasons] = @content.seasons.order(position: :asc).map do |season|
        season_data = season.as_json(except: %i[created_at updated_at])
        season_data[:episodes] = season.episodes.order(position: :asc).as_json(only: %i[id title description thumbnail position duration])
        season_data
      end
    end

    data[:deviceSessionToken] = @stream_session_result.session_id if @stream_session_result&.session_id.present?

    response = { data: data }
    render json: response
  end

  def video_sources_data
    {
      sources: @content.video_sources.content_sources.map do |vs|
        {
          id: vs.id,
          url: vs.url,
          quality: vs.quality,
        }
      end,
      segments: @content.segments.order(:start_time).as_json(only: %i[id segment_type start_time end_time])
    }
  end

  def episode_video_sources_data
    {
      sources: @episode.video_sources.content_sources.map do |vs|
        {
          id: vs.id,
          url: vs.url,
          quality: vs.quality,
        }
      end,
      segments: @episode.segments.order(:start_time).as_json(only: %i[id segment_type start_time end_time])
    }
  end

  def content_available?
    return false if @content.blank?

    if @content.content_type == "MOVIE"
      @content.available && !@content.video_sources.content_sources.empty?
    else
      @content.available
    end
  end

  def render_content_not_available
    respond_to do |format|
      format.html { render template: "application/index", status: :unprocessable_entity }
      format.json do
        render json: {
          errors: ["El contenido no está disponible para su reproducción."],
          error_type: "content_not_available",
        }, status: :unprocessable_entity
      end
    end
  end

  def stream_device_name
    sanitize_device_name(params[:device_name].presence || request.user_agent)
  end

  def stream_device_type
    return params[:device_type].to_s if params[:device_type].present?

    user_agent = request.user_agent.to_s.downcase
    return "tv" if user_agent.match?(/smarttv|hbbtv|appletv|roku|bravia|firetv|satellite|xbox|playstation|tv/i)
    return "mobile" if user_agent.match?(/iphone|ipad|android|mobile|tablet|ios|ipod/i)

    "desktop"
  end

  def sanitize_device_name(name)
    sanitized = name.to_s.strip
    sanitized = "Unknown Device" if sanitized.blank?
    sanitized.truncate(100)
  end

  def render_subscription_required
    respond_to do |format|
      format.html { render template: "application/index", status: :forbidden }
      format.json do
        render json: {
          errors: ["Se requiere una suscripción activa para ver este contenido."],
          error_type: "subscription_required",
        }, status: :forbidden
      end
    end
  end

  def create_watch_session(profile, ip_address)
    country_code = nil
    if ip_address.present?
      ip_info = IpInfo.lookup(ip_address)
      country_code = ip_info[:country_code] if ip_info[:country_code].present?
    end

    WatchSession.create!(
      profile: profile,
      content: @content,
      episode: @episode,
      started_at: Time.current,
      duration_watched: 0,
      total_duration: 0,
      completed: false,
      country_code: country_code
    )
  rescue StandardError => e
    Rails.logger.error "Error creating watch session: #{e.message}"
  end

  def update_watch_session(profile, content_id, episode_id, progress, duration)
    session = WatchSession.active
                          .where(profile: profile, content_id: content_id)
                          .where(episode_id: episode_id)
                          .order(started_at: :desc)
                          .first

    return unless session

    current_pos = progress.to_i
    last_pos = session.last_progress.to_i

    delta = [current_pos - last_pos, 0].max
    new_watched = session.duration_watched + delta
    dur = duration > 0 ? duration : session.total_duration
    new_watched = [new_watched, dur].min if dur > 0

    completed = dur > 0 && (new_watched.to_f / dur) >= 0.9

    session.update!(
      duration_watched: new_watched,
      last_progress: current_pos,
      total_duration: dur,
      completed: completed,
      ended_at: completed ? Time.current : nil
    )
  end

  def render_content_not_found
    render json: {
      errors: ["Content not found"],
      error_type: "content_not_found",
    }, status: :not_found
  end
end
