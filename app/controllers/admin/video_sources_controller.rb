# frozen_string_literal: true

module Admin
  class VideoSourcesController < Admin::BaseController
    before_action :set_videoable, only: [:index, :create]
    before_action :set_video_source, only: [:update, :destroy]

    def index
      sources = @videoable.video_sources
      if params[:trailer].present?
        sources = sources.where(trailer: params[:trailer] == "true")
      else
        sources = sources.content_sources
      end
      render json: sources
    end

    def create
      if params[:video_source][:file]
        handle_file_upload
      elsif params[:video_source][:url]
        handle_url_creation
      else
        render json: { error: 'You must provide either a file or a URL' }, status: :unprocessable_entity
      end
    end

    def update
      if @video_source.update(video_source_params)
        render json: @video_source
      else
        render json: { errors: @video_source.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @video_source.destroy
      head :no_content
    end

    def broken
      @broken_sources = VideoSource.where(media_status: 'broken')
                                   .includes(videoable: { season: :content })
                                   .map do |source|
        parent_title = source.videoable.try(:title) || "Unknown"
        content_title = if source.videoable_type == "Episode"
                          source.videoable&.season&.content&.title
                        end

        {
          id: source.id,
          url: source.url,
          quality: source.quality,
          format: source.format,
          failure_count: source.failure_count,
          last_checked_at: source.last_checked_at,
          videoable_type: source.videoable_type,
          videoable_id: source.videoable_id,
          parent_title: parent_title,
          content_title: content_title
        }
      end

      render json: { video_sources: @broken_sources }
    end

    def check
      @video_source = VideoSource.find(params[:id])
      VideoSourceMediaCheckerJob.perform_async(@video_source.id)

      render json: {
        message: "Integrity check queued for VideoSource #{@video_source.id}",
        video_source: {
          id: @video_source.id,
          media_status: @video_source.media_status,
          failure_count: @video_source.failure_count,
        },
      }
    end

    private

    def handle_file_upload
      uploaded_file = params[:video_source][:file]

      # Define a temporary path to store the uploaded file
      temp_path = Rails.root.join('tmp', 'uploads', uploaded_file.original_filename)

      # Ensure the directory exists
      FileUtils.mkdir_p(File.dirname(temp_path))

      # Save the file
      File.open(temp_path, 'wb') do |file|
        file.write(uploaded_file.read)
      end

      @video_source = @videoable.video_sources.new(
        quality: params[:video_source][:quality],
        format: params[:video_source][:format],
        storage_location: 'local',
        status: 'pending',
        temp_path: temp_path.to_s,
        trailer: params[:video_source][:trailer] || false
      )

      if @video_source.save
        VideoTranscodingJob.perform_async(@video_source.id)
        render json: @video_source, status: :created
      else
        render json: { errors: @video_source.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def handle_url_creation
      @video_source = @videoable.video_sources.new(video_source_params.merge(status: 'completed'))
      if @video_source.save
        render json: @video_source, status: :created
      else
        render json: { errors: @video_source.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def set_videoable
      if params[:content_id]
        @videoable = Content.find(params[:content_id])
      elsif params[:episode_id]
        @videoable = Episode.find(params[:episode_id])
      else
        render json: { error: 'Videoable not found' }, status: :not_found
      end
    end

    def set_video_source
      @video_source = VideoSource.find(params[:id])
    end

    def video_source_params
      params.require(:video_source).permit(:url, :quality, :format, :storage_location, :status, :temp_path, :file, :trailer)
    end
  end
end
