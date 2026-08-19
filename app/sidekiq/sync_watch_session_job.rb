# frozen_string_literal: true

class SyncWatchSessionJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  COMPLETION_THRESHOLD = 0.9

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

    threshold = completion_threshold(content_id, episode_id, dur)
    completed = dur > 0 && (new_watched.to_f / dur) >= threshold

    session.update!(
      duration_watched: new_watched,
      last_progress: current_pos,
      total_duration: dur,
      completed: completed,
      ended_at: completed ? Time.current : nil
    )

    mark_continue_watching_finished(profile_id, content_id, episode_id) if completed
  end

  private

  def completion_threshold(content_id, episode_id, total_duration)
    segmentable = if episode_id.present?
                    Episode.find_by(id: episode_id)
                  else
                    Content.find_by(id: content_id)
                  end

    return COMPLETION_THRESHOLD unless segmentable

    credits_segment = segmentable.segments.find_by(segment_type: :credits_start)
    return COMPLETION_THRESHOLD unless credits_segment&.start_time&.positive?

    return COMPLETION_THRESHOLD if total_duration <= 0

    credits_segment.start_time / total_duration
  end

  def mark_continue_watching_finished(profile_id, content_id, episode_id)
    cw = ContinueWatching.find_by(
      profile_id: profile_id,
      content_id: content_id,
      episode_id: episode_id
    )

    cw&.update!(finished: true)

    CinelarTV.cache.delete_matched("homepage/personal/#{profile_id}/*")
  end
end
