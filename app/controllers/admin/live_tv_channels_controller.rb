# frozen_string_literal: true

module Admin
  class LiveTvChannelsController < Admin::BaseController
    before_action :set_channel, only: [:update, :destroy]

    def index
      @channels = LiveTvChannel.order(:position)

      respond_to do |format|
        format.html
        format.json do
          render json: {
            live_tv_channels: @channels.map { |ch| channel_json(ch) }
          }
        end
      end
    end

    def create
      @channel = LiveTvChannel.new(channel_params)

      if @channel.save
        respond_to do |format|
          format.html { redirect_to admin_live_tv_channels_path, notice: "Channel created successfully." }
          format.json { render json: @channel, status: :created }
        end
      else
        respond_to do |format|
          format.html { render :index, status: :unprocessable_entity }
          format.json { render json: { errors: @channel.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def update
      if @channel.update(channel_params)
        respond_to do |format|
          format.html { redirect_to admin_live_tv_channels_path, notice: "Channel updated successfully." }
          format.json { render json: @channel }
        end
      else
        respond_to do |format|
          format.html { render :index, status: :unprocessable_entity }
          format.json { render json: { errors: @channel.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @channel.destroy
      respond_to do |format|
        format.html { redirect_to admin_live_tv_channels_path, notice: "Channel deleted successfully." }
        format.json { head :no_content }
      end
    end

    def reorder
      channel_ids = params[:channel_ids]
      return render_error("channel_ids parameter is required", :unprocessable_entity) unless channel_ids

      channel_ids.each_with_index do |id, index|
        LiveTvChannel.where(id: id).update_all(position: index)
      end

      respond_to do |format|
        format.html { redirect_to admin_live_tv_channels_path, notice: "Channels reordered successfully." }
        format.json { render json: { message: "Channels reordered successfully" } }
      end
    end

    private

    def set_channel
      @channel = LiveTvChannel.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_error("Channel not found", :not_found)
    end

    def channel_params
      params.require(:live_tv_channel).permit(
        :name, :description, :logo_url, :stream_url, :stream_format,
        :is_active, :position, :xmltv_channel_id
      )
    end

    def channel_json(channel)
      {
        id: channel.id,
        name: channel.name,
        description: channel.description,
        logo_url: channel.logo_url,
        stream_url: channel.stream_url,
        stream_format: channel.stream_format,
        is_active: channel.is_active,
        position: channel.position,
        xmltv_channel_id: channel.xmltv_channel_id,
        current_program: channel.current_program&.as_json(only: %i[id title description start_time end_time]),
        created_at: channel.created_at,
        updated_at: channel.updated_at,
      }
    end

    def render_error(message, status)
      respond_to do |format|
        format.html { redirect_to admin_live_tv_channels_path, alert: message }
        format.json { render json: { error: message }, status: status }
      end
    end
  end
end
