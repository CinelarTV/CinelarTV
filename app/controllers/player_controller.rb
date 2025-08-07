# frozen_string_literal: true

class PlayerController < ApplicationController
  before_action :authenticate_user!
  before_action :find_content, only: :watch
  before_action :check_content_availability, only: :watch

  def watch
    return unless @content

    find_episode_and_season if @content.content_type == "TVSHOW"

    profile = Profile.find_by(id: session[:current_profile_id])
    continue_watching = create_or_find_continue_watching(profile)

    reproduction = Reproduction.new(
      profile_id: profile.id,
      content_id: @content.id,
      played_at: Time.now,
    )

    ip_address = nil

    if Rails.env.production?
      ip_address = request.remote_ip
    else
      begin
        ip_address = Net::HTTP.get(URI.parse("http://checkip.amazonaws.com/")).squish
      rescue StandardError => e
        Rails.logger.error "Error fetching IP address: #{e.message}"
      end
    end

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
    profile = Profile.find_by(id: session[:current_profile_id])
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
      data[:sources] = video_sources_data
    elsif @content.content_type == "TVSHOW" && @episode
      data[:sources] = episode_video_sources_data
    end

    if @content.content_type == "TVSHOW" && @episode
      data[:episode] = @episode.as_json(except: %i[created_at updated_at])
    end
    data[:season] = @season.as_json(except: %i[created_at updated_at]) if @season
    data[:season][:episodes] = @season.episodes.order(position: :asc).as_json(only: %i[id title description thumbnail position]) if @season

    render json: { data: data }
  end

  def video_sources_data
    @content.video_sources.map do |vs|
      {
        id: vs.id,
        url: vs.url,
        quality: vs.quality,
      }
    end
  end

  def episode_video_sources_data
    @episode.video_sources.map do |vs|
      {
        id: vs.id,
        url: vs.url,
        quality: vs.quality,
      }
    end
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
    render json: {
      errors: ["El contenido no está disponible para su reproducción."],
      error_type: "content_not_available",
    }, status: :unprocessable_entity
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
