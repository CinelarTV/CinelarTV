# frozen_string_literal: true

class VideoSourceMediaCheckerJob
  include Sidekiq::Job

  def perform(video_source_id)
    video_source = VideoSource.find_by(id: video_source_id)
    return unless video_source

    video_source.checking!

    result = MediaIntegrityCheckService.new(video_source).check

    if result[:success]
      video_source.update(
        media_status: "verified",
        failure_count: 0,
        last_checked_at: Time.current
      )
    else
      handle_failure(video_source, result[:error])
    end
  end

  private

  def handle_failure(video_source, error_message)
    new_failure_count = video_source.failure_count + 1
    threshold = SiteSetting.media_checker_failure_threshold || 3

    status = new_failure_count >= threshold ? "broken" : "uncertain"

    video_source.update(
      media_status: status,
      failure_count: new_failure_count,
      last_checked_at: Time.current
    )

    if status == "uncertain"
      VideoSourceMediaCheckerJob.perform_in(4.hours, video_source.id)
    end

    Rails.logger.warn(
      "Media integrity check failed for VideoSource #{video_source.id}: " \
      "#{error_message} (Failures: #{new_failure_count})"
    )
  end
end
