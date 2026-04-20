# frozen_string_literal: true

class PlayerController < ApplicationController
  before_action :authenticate_user!
  before_action :find_content, only: :watch
  before_action :check_content_availability, only: :watch
  before_action :check_subscription, only: :watch

  def watch
    return respond_to do |format|
      format.html { render_content_not_available }
      format.json { render_content_not_available }
    end unless @content

    find_episode_and_season if @content.content_type == "TVSHOW"

    profile = current_profile
    continue_watching = create_or_find_continue_watching(profile)

    reproduction = Reproduction.new(
      profile_id: profile.id,
      content_id: @content.id,
      played_at: Time.now,
    )

    if request.format.json?
      @stream_session_result = StreamSessionManager.start_session(
        current_user,
        device_name: stream_device_name,
        device_type: stream_device_type,
        profile_id: profile&.id,
        requested_session_id: params[:deviceSessionToken].presence || params[:streamSessionToken].presence
      )

      if @stream_session_result.limit_reached?
        return respond_to do |format|
          format.html { render template: 'application/index', status: :forbidden }
          format.json { render json: { error: 'STREAM_LIMIT_REACHED', sessions: @stream_session_result.active_sessions }, status: :forbidden }
        end
      end
    else
      @stream_session_result = StreamSessionManager::Result.new(success: true, skipped: true)
    end

    ip_address = request.remote_ip

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

    respond_to do |format|
      format.html
      format.json { render_json_response(continue_watching) }
    end
  end

  def update_current_progress
    profile = current_profile
    @content = Content.find_by(id: params[:id])

    return render_content_not_found unless @content

    if @content.content_type == "TVSHOW"
      handle_tvshow_update(profile)
    elsif @content.content_type == "MOVIE"
      handle_movie_update(profile)
    else
      render_invalid_content_type
    end
  end

  private

  def find_content
    @content = Content.find_by(id: params[:id])
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
      episode_id: @episode&.id,
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
      continue_watching: continue_watching&.as_json(except: %i[created_at updated_at profile_id episode_id content_id id]),
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
    data[:season] = @season.as_json(except: %i[created_at updated_at]) if @season
    data[:season][:episodes] = @season.episodes.order(position: :asc).as_json(only: %i[id title description thumbnail position]) if @season

    
    response = { data: data }
    response[:deviceSessionToken] = @stream_session_result.session_id if @stream_session_result&.session_id.present?

    render json: response
  end

  def video_sources_data
    {
      sources: @content.video_sources.map do |vs|
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
      sources: @episode.video_sources.map do |vs|
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
      @content.available && !@content.video_sources.empty?
    else
      @content.available
    end
  end

  def render_content_not_available
    respond_to do |format|
      format.html { render template: 'application/index', status: :unprocessable_entity }
      format.json {
        render json: {
          errors: ["El contenido no está disponible para su reproducción."],
          error_type: "content_not_available",
        }, status: :unprocessable_entity
      }
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
      format.html { render template: 'application/index', status: :forbidden }
      format.json {
        render json: {
          errors: ["Se requiere una suscripción activa para ver este contenido."],
          error_type: "subscription_required",
        }, status: :forbidden
      }
    end
  end

  def handle_tvshow_update(profile)
    episode = Episode.find_by(id: params[:episode_id])

    if episode
      continue_watching = ContinueWatching.find_or_create_by(
        profile_id: profile.id,
        content_id: @content.id,
        episode_id: episode.id,
      )

      update_continue_watching(continue_watching)
    else
      render_episode_not_found
    end
  end

  def handle_movie_update(profile)
    continue_watching = ContinueWatching.find_or_create_by(
      profile_id: profile.id,
      content_id: @content.id,
    )

    update_continue_watching(continue_watching)
  end

  def update_continue_watching(continue_watching)
    progress = params[:progress].to_d
    duration = params[:duration].to_d

    continue_watching.update(
      progress: progress,
      duration: duration,
      last_watched_at: Time.current,
    )

    head :no_content
  end

  def render_content_not_found
    render json: {
      errors: ["Content not found"],
      error_type: "content_not_found",
    }, status: :not_found
  end

  def render_episode_not_found
    render json: {
      message: "Episodio no encontrado.",
    }, status: :not_found
  end

  def render_invalid_content_type
    render json: {
      message: "Tipo de contenido no válido.",
    }, status: :unprocessable_entity
  end
end
