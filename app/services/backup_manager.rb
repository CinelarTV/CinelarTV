# frozen_string_literal: true

require "fileutils"
require "digest"

class BackupManager
  class RestoreDisabledError < StandardError; end
  class BackupError < StandardError; end
  class RestoreError < StandardError; end

  UPLOAD_DIRECTORIES = %w[
    uploads/content_images/banners
    uploads/content_images/covers
    uploads/content_images/episode_thumbnails
    uploads/logos
    public/content-media
  ].freeze

  # --- Create backup ---

  def self.create_backup(notes: nil, backup_type: "manual", include_files: true, encrypt: false)
    Backup.ensure_base_directory_exists!

    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    filename = "cinelar_backup_#{timestamp}.dump"
    filepath = File.join(Backup.base_directory, filename)

    backup = Backup.create!(
      filename: filename,
      backup_type: backup_type,
      status: "running",
      notes: notes,
      source: "system",
      retention_days: SiteSetting.backup_retention_days || 30,
      expires_at: (SiteSetting.backup_retention_days || 30).days.from_now
    )

    begin
      backup.append_audit("started", "backup_type=#{backup_type}, include_files=#{include_files}")

      # 1. Database dump
      run_pg_dump(filepath, backup)
      backup.update!(size: File.size(filepath))

      # 2. File manifest (track uploaded files)
      if include_files
        manifest = build_file_manifest
        backup.update!(file_manifest: manifest)
        backup.append_audit("files_manifested", "#{manifest[:total_files]} files, #{manifest[:total_size]} bytes")
      end

      # 3. Encryption
      if encrypt
        password = SiteSetting.backup_encryption_password
        if password.present?
          backup.encrypt_file!(password)
        else
          backup.append_audit("encryption_skipped", "No encryption password configured")
        end
      end

      backup.mark_completed!
      backup
    rescue StandardError => e
      backup.mark_failed!(e.message)
      FileUtils.rm_f(filepath) if File.exist?(filepath)
      Rails.logger.error "Backup failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      raise BackupError, "Failed to create backup: #{e.message}"
    end
  end

  # --- Restore from backup ---

  def self.restore_backup(filename, force: false, restore_files: true)
    unless force || SiteSetting.allow_restore
      raise RestoreDisabledError, "Restoration is disabled. Enable 'allow_restore' in Site Settings."
    end

    backup = Backup.find_by!(filename: filename)
    filepath = backup.path

    unless File.exist?(filepath)
      raise RestoreError, "Backup file not found on disk: #{filename}"
    end

    # Verify checksum if available
    if backup.checksum.present?
      actual = Digest::SHA256.file(filepath).hexdigest
      unless actual == backup.checksum
        raise RestoreError, "Checksum mismatch! Backup file may be corrupted."
      end
    end

    # Decrypt if needed
    if backup.encrypted?
      password = SiteSetting.backup_encryption_password
      raise RestoreError, "Backup is encrypted but no password configured" if password.blank?
      backup.decrypt_file!(password)
    end

    backup.append_audit("restore_started")

    # 1. Restore database
    run_pg_restore(filepath, backup)

    # 2. Restore file manifest info
    if restore_files && backup.file_manifest.present?
      backup.append_audit("files_manifest_restored", "File manifest available for manual restoration")
    end

    backup.append_audit("restore_completed")
    true
  end

  # --- Download ---

  def self.download_path(filename)
    backup = Backup.find_by!(filename: filename)
    return nil unless backup.exist?
    backup.path
  end

  private

  def self.run_pg_dump(filepath, backup)
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash

    env = {
      "PGPASSWORD" => db_config[:password].to_s,
      "PGSSLMODE" => db_config[:sslmode].to_s
    }

    command = [
      "pg_dump",
      "-h", db_config[:host] || "localhost",
      "-p", (db_config[:port] || 5432).to_s,
      "-U", db_config[:username],
      "-F", "c",
      "-f", filepath,
      db_config[:database]
    ]

    backup.append_audit("pg_dump_started")
    success = system(env, *command)

    unless success
      raise BackupError, "pg_dump exited with non-zero status"
    end

    backup.append_audit("pg_dump_completed")
  end

  def self.run_pg_restore(filepath, backup)
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash

    env = {
      "PGPASSWORD" => db_config[:password].to_s,
      "PGSSLMODE" => db_config[:sslmode].to_s
    }

    command = [
      "pg_restore",
      "-h", db_config[:host] || "localhost",
      "-p", (db_config[:port] || 5432).to_s,
      "-U", db_config[:username],
      "-d", db_config[:database],
      "-c",
      "--if-exists",
      filepath
    ]

    backup.append_audit("pg_restore_started")
    success = system(env, *command)

    unless success
      raise RestoreError, "pg_restore exited with non-zero status"
    end

    backup.append_audit("pg_restore_completed")
  end

  def self.build_file_manifest
    manifest = { files: [], total_files: 0, total_size: 0 }
    root = Rails.root

    UPLOAD_DIRECTORIES.each do |dir|
      full_path = root.join(dir)
      next unless Dir.exist?(full_path)

      Dir.glob(File.join(full_path, "**", "*")).select { |f| File.file?(f) }.each do |file|
        relative = file.sub(root.to_s, "")
        size = File.size(file)
        manifest[:files] << {
          path: relative,
          size: size,
          checksum: Digest::SHA256.file(file).hexdigest,
          modified_at: File.mtime(file).iso8601
        }
        manifest[:total_files] += 1
        manifest[:total_size] += size
      end
    end

    manifest
  end
end
