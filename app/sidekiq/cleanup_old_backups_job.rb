# frozen_string_literal: true

class CleanupOldBackupsJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 2

  def perform
    cleaned = Backup.cleanup_expired!
    Rails.logger.info "Cleaned up #{cleaned} expired backups"
  end
end
