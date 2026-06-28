# frozen_string_literal: true

class BackfillWatchSessionsJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform
    Rails.logger.info "Backfilling watch sessions from reproductions..."

    Reproduction.find_each do |reproduction|
      next if WatchSession.exists?(profile: reproduction.profile, content: reproduction.content, started_at: reproduction.played_at)

      WatchSession.create!(
        profile: reproduction.profile,
        content: reproduction.content,
        started_at: reproduction.played_at,
        ended_at: reproduction.played_at,
        duration_watched: 0,
        total_duration: 0,
        completed: false,
        country_code: reproduction.country_code
      )
    rescue StandardError => e
      Rails.logger.error "Error backfilling watch session for reproduction #{reproduction.id}: #{e.message}"
    end

    Rails.logger.info "Watch sessions backfill complete."
  end
end
