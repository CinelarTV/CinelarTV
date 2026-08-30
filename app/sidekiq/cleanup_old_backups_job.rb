# frozen_string_literal: true

class CleanupOldBackupsJob
  include Sidekiq::Job
  extend MiniScheduler::Schedule

  sidekiq_options queue: :default, retry: 2

  daily at: 4.hours

  def perform
    cleaned = Backup.cleanup_expired!
    Rails.logger.info "Cleaned up #{cleaned} expired backups"
  end
end
