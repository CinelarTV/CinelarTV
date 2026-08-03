# frozen_string_literal: true

class SyncWatchSessionJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  def perform(profile_id, content_id, episode_id, progress, duration)
    session = WatchSession.active
                          .where(profile_id: profile_id, content_id: content_id)
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
end
