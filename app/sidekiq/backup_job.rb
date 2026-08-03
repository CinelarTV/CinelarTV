# frozen_string_literal: true

class BackupJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 1

  def perform(notes: nil, backup_type: "scheduled", include_files: true, encrypt: false)
    Rails.logger.info "Starting scheduled backup job"
    BackupManager.create_backup(
      notes: notes,
      backup_type: backup_type,
      include_files: include_files,
      encrypt: encrypt
    )
  rescue StandardError => e
    Rails.logger.error "BackupJob failed: #{e.message}"
    raise
  end
end
