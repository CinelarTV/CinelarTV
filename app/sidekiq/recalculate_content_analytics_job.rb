# frozen_string_literal: true

class RecalculateContentAnalyticsJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform
    Rails.logger.info "Recalculating content analytics..."

    WatchSession.distinct.pluck(:content_id).each do |content_id|
      content = Content.find_by(id: content_id)
      next unless content

      ContentAnalytic.recalculate!(content)
    rescue StandardError => e
      Rails.logger.error "Error recalculating analytics for content #{content_id}: #{e.message}"
    end

    Rails.logger.info "Content analytics recalculation complete."
  end
end
