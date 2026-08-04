# frozen_string_literal: true

class RestoreJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 0

  PROGRESS_CHANNEL = "/admin/backups/%{backup_id}/restore"

  def perform(backup_id, force: false, restore_files: true)
    backup = Backup.find(backup_id)
    channel = PROGRESS_CHANNEL % { backup_id: backup_id }

    publish(channel, type: "started", message: "Restore initiated")
    backup.update!(status: "running")

    # 1. Validate
    publish(channel, type: "progress", step: "validating", percent: 5, message: "Validating backup...")
    RestoreManager.validate_backup!(backup)

    # 2. Decrypt if needed
    if backup.encrypted?
      publish(channel, type: "progress", step: "decrypting", percent: 10, message: "Decrypting backup...")
      password = SiteSetting.backup_encryption_password
      raise RestoreManager::RestoreError, "Backup is encrypted but no password configured" if password.blank?
      backup.decrypt_file!(password)
    end

    # 3. Extract zip
    publish(channel, type: "progress", step: "extracting", percent: 15, message: "Extracting backup archive...")
    tmp_dir = Rails.root.join("tmp", "restore_#{backup.id}")
    FileUtils.mkdir_p(tmp_dir)

    begin
      Zip::File.open(backup.path) do |zipfile|
        zipfile.extract("database.dump", File.join(tmp_dir, "database.dump"))
        if restore_files && zipfile.find_entry("manifest.json")
          zipfile.extract("manifest.json", File.join(tmp_dir, "manifest.json"))
        end
      end

      # 4. Restore database
      publish(channel, type: "progress", step: "restoring_database", percent: 30, message: "Restoring database...")
      dump_path = File.join(tmp_dir, "database.dump")
      BackupManager.send(:run_pg_restore, dump_path, backup)
      publish(channel, type: "progress", step: "database_done", percent: 70, message: "Database restored")

      # 5. Restore files
      if restore_files
        publish(channel, type: "progress", step: "restoring_files", percent: 75, message: "Restoring uploaded files...")
        restored = BackupManager.send(:restore_uploaded_files, backup.path)
        backup.append_audit("files_restored", "#{restored} files")
        publish(channel, type: "progress", step: "files_done", percent: 90, message: "#{restored} files restored")
      else
        backup.append_audit("files_manifest_restored", "Skipped uploaded files")
        publish(channel, type: "progress", step: "files_done", percent: 90, message: "File restore skipped")
      end

      # 6. Validate schema
      publish(channel, type: "progress", step: "validating_schema", percent: 95, message: "Validating schema...")
      RestoreManager.validate_schema! if restore_files

      backup.mark_completed!
      backup.append_audit("restore_completed")
      publish(channel, type: "completed", percent: 100, message: "Restore completed successfully")
    ensure
      FileUtils.rm_rf(tmp_dir) if Dir.exist?(tmp_dir)
    end
  rescue StandardError => e
    Rails.logger.error "RestoreJob failed: #{e.message}"
    backup&.update!(status: "failed", error_message: e.message)
    backup&.append_audit("restore_failed", e.message)
    publish(channel, type: "failed", message: e.message)
  end

  private

  def publish(channel, data)
    MessageBus.publish(channel, data.merge(timestamp: Time.current.to_i))
  rescue StandardError => e
    Rails.logger.warn "Failed to publish restore progress: #{e.message}"
  end
end
