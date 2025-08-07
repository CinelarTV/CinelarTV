# frozen_string_literal: true

class VideoTranscodingJob
  include Sidekiq::Job

  def perform(video_source_id)
    video_source = VideoSource.find(video_source_id)
    return unless video_source && video_source.status == 'pending' && video_source.temp_path.present?

    video_source.update(status: 'processing')

    # Placeholder for transcoding logic
    # In a real application, this would call a service to:
    # 1. Download the file from temp_path
    # 2. Run ffmpeg or a similar tool
    # 3. Upload the resulting m3u8 and ts files to a permanent location
    # 4. Get the new URL

    # For this example, we'll simulate a successful transcoding
    sleep 10 # Simulate work
    transcoded_url = "/uploads/transcoded/#{File.basename(video_source.temp_path)}.m3u8"

    video_source.update(
      url: transcoded_url,
      status: 'completed',
      temp_path: nil # Clean up temp_path after successful transcoding
    )
  rescue StandardError => e
    # If anything goes wrong, mark as failed
    video_source&.update(status: 'failed')
    # Optionally, log the error
    Rails.logger.error "Transcoding failed for VideoSource #{video_source_id}: #{e.message}"
  end
end
