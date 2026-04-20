# frozen_string_literal: true

module Admin
  class SegmentsController < Admin::BaseController
    before_action :set_segmentable
    before_action :set_segment, only: [:update, :destroy]

    def index
    render json: @segmentable.segments
  end

  def create
      @segment = @segmentable.segments.new(segment_params)

      # Ensure only one segment of each type
      existing_segment = @segmentable.segments.find_by(segment_type: @segment.segment_type)
      if existing_segment
        render json: { error: "A segment of type #{@segment.segment_type} already exists" }, status: :unprocessable_entity
        return
      end

      if @segment.save
        render json: { segment: @segment }, status: :created
      else
        render json: { errors: @segment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @segment.update(segment_params)
        render json: { segment: @segment }
      else
        render json: { errors: @segment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @segment.destroy
      render json: { message: "Segment deleted successfully" }
    end

    private

    def set_segmentable
      if params[:content_id].present?
        @segmentable = Content.find(params[:content_id])
      elsif params[:episode_id].present?
        @segmentable = Episode.find(params[:episode_id])
      else
        render json: { error: "Segmentable not found" }, status: :not_found
      end
    end

    def set_segment
      @segment = @segmentable.segments.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Segment not found" }, status: :not_found
    end

    def segment_params
      params.require(:segment).permit(:segment_type, :start_time, :end_time)
    end
  end
end
