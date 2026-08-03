# frozen_string_literal: true

class RestoreJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 0

  def perform(filename, force: false, restore_files: true)
    Rails.logger.info "Starting restore job for: #{filename}"
    RestoreManager.restore(filename, force: force, restore_files: restore_files)
  rescue StandardError => e
    Rails.logger.error "RestoreJob failed: #{e.message}"
    raise
  end
end
