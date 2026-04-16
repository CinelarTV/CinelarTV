# frozen_string_literal: true

require "fileutils"

class BackupManager
  class RestoreDisabledError < StandardError; end
  class BackupError < StandardError; end

  def self.create_backup(notes: nil, backup_type: "manual")
    Backup.ensure_base_directory_exists!
    
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    filename = "cinelar_backup_#{timestamp}.dump"
    filepath = File.join(Backup.base_directory, filename)

    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    
    # Construct pg_dump command
    # -F c: Custom format (recommended for pg_restore)
    # -v: Verbose
    # -f: Output file
    
    env = {
      "PGPASSWORD" => db_config[:password].to_s
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

    Rails.logger.info "Starting backup: #{filename}"
    
    success = system(env, *command)

    if success
      size = File.size(filepath)
      backup = Backup.create!(
        filename: filename,
        size: size,
        backup_type: backup_type,
        notes: notes,
        source: "system"
      )
      Rails.logger.info "Backup created successfully: #{filename} (#{size} bytes)"
      backup
    else
      Rails.logger.error "Backup failed: pg_dump exited with non-zero status"
      FileUtils.rm_f(filepath) if File.exist?(filepath)
      raise BackupError, "Failed to create database dump"
    end
  end

  def self.restore_backup(filename, force: false)
    unless force || SiteSetting.allow_restore
      raise RestoreDisabledError, "Restoration is disabled by default. Enable it in Site Settings or use FORCE=true via Rake."
    end

    backup = Backup.find_by!(filename: filename)
    filepath = backup.path

    unless File.exist?(filepath)
      raise BackupError, "Backup file not found on disk: #{filename}"
    end

    db_config = ActiveRecord::Base.connection_db_config.configuration_hash

    # Construct pg_restore command
    # -c: Clean (drop database objects before recreating)
    # --if-exists: Use with -c
    # -d: Database name
    # -v: Verbose
    
    env = {
      "PGPASSWORD" => db_config[:password].to_s
    }

    # IMPORTANT: We need to disconnect other sessions if possible, or warn the user.
    # In a development/simple environment, -c --if-exists is usually enough if no one is using the DB.
    
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

    Rails.logger.info "Starting restoration of: #{filename}"
    
    # We might need to terminate other connections to the database to avoid "database is being accessed by other users" errors.
    # But for a basic implementation, we'll try pg_restore directly.
    
    success = system(env, *command)

    if success
      Rails.logger.info "Back up restored successfully: #{filename}"
      true
    else
      Rails.logger.error "Restoration failed: pg_restore exited with non-zero status"
      raise BackupError, "Failed to restore database from dump"
    end
  end
end
