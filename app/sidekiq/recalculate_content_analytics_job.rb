# frozen_string_literal: true

class RecalculateContentAnalyticsJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform
    Rails.logger.info "Recalculating content analytics..."

    # Single GROUP BY query — replaces N queries per content
    rows = WatchSession
      .where.not(content_id: nil)
      .group(:content_id)
      .select(<<-SQL.squish)
        content_id,
        COUNT(*) AS total_views,
        COUNT(*) FILTER (WHERE completed) AS completed_count,
        COUNT(DISTINCT profile_id) AS unique_profiles,
        COALESCE(SUM(duration_watched), 0) AS total_seconds,
        COALESCE(AVG(CASE WHEN total_duration > 0 THEN (duration_watched / total_duration * 100) ELSE 0 END), 0) AS avg_watch_percentage,
        MAX(started_at) AS last_watched_at
      SQL

    now = Time.current
    analytics_rows = rows.map do |row|
      total = row.total_views.to_i
      completed = row.completed_count.to_i
      {
        content_id: row.content_id,
        total_views: total,
        total_seconds_watched: row.total_seconds.to_f,
        unique_profiles: row.unique_profiles.to_i,
        completion_rate: total > 0 ? (completed.to_f / total * 100) : 0.0,
        avg_watch_percentage: row.avg_watch_percentage.to_f,
        last_watched_at: row.last_watched_at,
        created_at: now,
        updated_at: now
      }
    end

    if analytics_rows.any?
      ContentAnalytic.upsert_all(analytics_rows, unique_by: :content_id)
      Rails.logger.info "Upserted #{analytics_rows.size} content analytics."
    end

    Rails.logger.info "Content analytics recalculation complete."
  end
end
