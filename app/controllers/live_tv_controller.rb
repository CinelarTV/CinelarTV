# frozen_string_literal: true

class LiveTvController < ApplicationController
  before_action :check_live_tv_enabled
  before_action :set_channel, only: [:show, :watch, :guide]
  before_action :check_channel_active, only: [:show, :watch, :guide]

  def index
    @channels = LiveTvChannel.active.order(:position)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          live_tv_channels: @channels.map { |ch| channel_json(ch) }
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: channel_json(@channel)
      end
    end
  end

  def watch
    # For live TV, we don't create ContinueWatching records
    # But we do track reproductions for analytics
    if current_profile
      begin
        reproduction = Reproduction.new(
          profile_id: current_profile.id,
          content_id: nil, # Live TV doesn't use Content model
          played_at: Time.current,
        )

        # Set country code if possible
        ip_address = request.remote_ip
        reproduction.set_country_code(ip_address) if ip_address.present?

        reproduction.save
      rescue StandardError => e
        Rails.logger.error "Error saving reproduction for live TV: #{e.message}"
      end
    end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          live_tv_channel: {
            id: @channel.id,
            name: @channel.name,
            stream_url: helpers.resolve_stream_url(@channel.stream_url),
            stream_format: @channel.stream_format,
            logo_url: @channel.logo_url,
            current_program: @channel.current_program&.as_json(only: %i[id title description start_time end_time icon_url category]),
            is_live: true,
          }
        }
      end
    end
  end

  def guide
    start_time = params[:start_time] ? Time.zone.parse(params[:start_time]) : Time.current.beginning_of_day
    end_time = params[:end_time] ? Time.zone.parse(params[:end_time]) : Time.current.end_of_day

    @programs = @channel.tv_programs.for_time_range(start_time, end_time)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          live_tv_channel_id: @channel.id,
          channel_name: @channel.name,
          programs: @programs.map { |p| program_json(p) },
          start_time: start_time,
          end_time: end_time,
        }
      end
    end
  end

  private

  def set_channel
    @channel = LiveTvChannel.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Live TV channel not found", :not_found)
  end

  def check_channel_active
    return if @channel.is_active

    render_error("Live TV channel is not active", :not_found)
  end

  def check_live_tv_enabled
    return if SiteSetting.enable_live_tv

    render_error("Live TV is disabled", :service_unavailable)
  end

  def channel_json(channel)
    {
      id: channel.id,
      name: channel.name,
      description: channel.description,
      logo_url: channel.logo_url,
      stream_url: helpers.resolve_stream_url(channel.stream_url),
      stream_format: channel.stream_format,
      is_active: channel.is_active,
      xmltv_channel_id: channel.xmltv_channel_id,
      current_program: channel.current_program&.as_json(only: %i[id title description start_time end_time icon_url category]),
      upcoming_programs: channel.upcoming_programs(3).map { |p| program_json(p) },
      created_at: channel.created_at,
      updated_at: channel.updated_at,
    }
  end

  def program_json(program)
    {
      id: program.id,
      title: program.title,
      description: program.description,
      start_time: program.start_time,
      end_time: program.end_time,
      icon_url: program.icon_url,
      category: program.category,
      currently_playing: program.currently_playing?,
    }
  end

  def render_error(message, status)
    respond_to do |format|
      format.html { redirect_to root_path, alert: message }
      format.json { render json: { error: message }, status: status }
    end
  end
end
