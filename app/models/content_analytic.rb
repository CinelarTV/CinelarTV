# frozen_string_literal: true

class ContentAnalytic < ApplicationRecord
  belongs_to :content

  def self.recalculate!(content)
    sessions = WatchSession.where(content: content)
    return if sessions.empty?

    completed_count = sessions.completed.count
    total_count = sessions.count
    unique_profile_ids = sessions.distinct.pluck(:profile_id)

    total_seconds = sessions.sum(:duration_watched)
    avg_percentage = if total_count > 0
                       sessions.average(Arel.sql("CASE WHEN total_duration > 0 THEN (duration_watched / total_duration * 100) ELSE 0 END")).to_f
                     else
                       0.0
                     end

    analytics = find_or_initialize_by(content: content)
    analytics.update!(
      total_views: total_count,
      total_seconds_watched: total_seconds,
      unique_profiles: unique_profile_ids.size,
      completion_rate: total_count > 0 ? (completed_count.to_f / total_count * 100) : 0.0,
      avg_watch_percentage: avg_percentage,
      last_watched_at: sessions.maximum(:started_at)
    )
  end

  def total_hours_watched
    (total_seconds_watched / 3600.0).round(1)
  end
end
