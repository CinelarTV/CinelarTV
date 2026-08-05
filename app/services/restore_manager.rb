# frozen_string_literal: true

class RestoreManager
  class RestoreError < StandardError; end

  # Restore from a backup file with full validation
  def self.restore(filename, options = {})
    force = options.fetch(:force, false)
    restore_files = options.fetch(:restore_files, true)

    backup = Backup.find_by!(filename: filename)
    validate_backup!(backup)

    Rails.logger.info "Starting restore from #{filename}"
    backup.append_audit("restore_initiated", "options=#{options}")

    # Database restore
    BackupManager.restore_backup(filename, force: force, restore_files: restore_files)

    # Post-restore validation
    validate_schema! if restore_files

    backup.append_audit("restore_validated")
    Rails.logger.info "Restore completed successfully from #{filename}"
    true
  rescue StandardError => e
    Rails.logger.error "Restore failed: #{e.message}"
    backup&.append_audit("restore_failed", e.message) if backup
    raise RestoreError, "Restore failed: #{e.message}"
  end

  # Partial restore: only specific tables
  def self.restore_tables(filename, table_names)
    backup = Backup.find_by!(filename: filename)
    validate_backup!(backup)

    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    env = {
      "PGPASSWORD" => db_config[:password].to_s,
      "PGSSLMODE" => db_config[:sslmode].to_s
    }

    table_names.each do |table|
      command = [
        "pg_restore",
        "-h", db_config[:host] || "localhost",
        "-p", (db_config[:port] || 5432).to_s,
        "-U", db_config[:username],
        "-d", db_config[:database],
        "-t", table,
        "--data-only",
        backup.path
      ]

      success = system(env, *command)
      unless success
        raise RestoreError, "Failed to restore table: #{table}"
      end
    end

    backup.append_audit("partial_restore", "tables=#{table_names.join(', ')}")
    true
  end

  # Validate a backup file exists and is usable
  def self.validate_backup!(backup)
    raise RestoreError, "Backup not found" unless backup
    raise RestoreError, "Backup file missing on disk: #{backup.filename}" unless backup.exist?
    raise RestoreError, "Backup status is '#{backup.status}', expected 'completed'" unless backup.status == "completed"

    # Verify checksum if available
    if backup.checksum.present?
      actual = Digest::SHA256.file(backup.path).hexdigest
      unless actual == backup.checksum
        raise RestoreError, "Checksum mismatch! File may be corrupted."
      end
    end
  end

  # Validate database schema after restore
  def self.validate_schema!
    expected_tables = %w[
      users profiles roles users_roles contents seasons episodes
      categories content_categories cast_members people likes dislikes
      video_sources segments reproductions watch_sessions continue_watchings
      content_analytics settings email_templates custom_pages backups
      live_tv_channels tv_programs xmltv_sources
      oauth_access_grants oauth_access_tokens oauth_applications oauth_device_grants
      subscriptions payments provider_events subscription_access_grants
      watch_party_sessions watch_party_session_users
      webhook_logs scheduler_stats preferences
    ]

    actual_tables = ActiveRecord::Base.connection.tables
    missing = expected_tables - actual_tables

    if missing.any?
      raise RestoreError, "Schema validation failed. Missing tables: #{missing.join(', ')}"
    end

    true
  end
end
