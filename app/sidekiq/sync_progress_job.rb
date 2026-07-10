# frozen_string_literal: true

class SyncProgressJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  def perform(profile_id, content_id, episode_id, progress, duration)
    cw = ContinueWatching.find_or_initialize_by(
      profile_id: profile_id,
      content_id: content_id,
      episode_id: episode_id
    )

    if cw.new_record? || cw.last_watched_at.nil? || cw.last_watched_at < Time.current
      cw.update!(
        progress: progress,
        duration: duration,
        last_watched_at: Time.current
      )
    end
  end
end
