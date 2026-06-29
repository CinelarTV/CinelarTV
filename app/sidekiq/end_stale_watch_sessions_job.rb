# frozen_string_literal: true

class EndStaleWatchSessionsJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  def perform
    Rails.logger.info "Closing stale watch sessions..."
    WatchSession.end_stale_sessions!
    Rails.logger.info "Stale watch sessions closed."
  end
end
