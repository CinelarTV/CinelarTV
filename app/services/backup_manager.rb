# frozen_string_literal: true

require "fileutils"
require "digest"
require "open3"
require "zip"
require "uri"

class BackupManager
  class RestoreDisabledError < StandardError; end
  class BackupError < StandardError; end
  class RestoreError < StandardError; end

  UPLOAD_DIRECTORIES = %w[
    public/uploads/content_images/banners
    public/uploads/content_images/covers
    public/uploads/content_images/episode_thumbnails
    public/uploads/logos
    public/content-media
  ].freeze

  # --- Create backup ---

  def self.create_backup(notes: nil, backup_type: "manual", include_files: true, encrypt: false)
    Backup.ensure_base_directory_exists!

    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    filename = "cinelar_backup_#{timestamp}.zip"
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

    tmp_dir = Rails.root.join("tmp", "backup_#{backup.id}")
    FileUtils.mkdir_p(tmp_dir)

    begin
      backup.append_audit("started", "backup_type=#{backup_type}, include_files=#{include_files}")

      # 1. Database dump into tmp
      dump_path = File.join(tmp_dir, "database.dump")
      run_pg_dump(dump_path, backup)

      # 2. Build file manifest and copy uploads into tmp
      manifest = { files: [], total_files: 0, total_size: 0, db_dump_size: File.size(dump_path) }
      uploads_dir = File.join(tmp_dir, "uploads")

      if include_files
        manifest = build_file_manifest(uploads_dir)
        backup.append_audit("files_manifested", "#{manifest[:total_files]} files, #{manifest[:total_size]} bytes")
      end

      # 3. Write manifest JSON into tmp
      manifest_path = File.join(tmp_dir, "manifest.json")
      File.write(manifest_path, JSON.pretty_generate(manifest))

      # 4. Create zip from tmp contents
      Zip::File.open(filepath, Zip::File::CREATE) do |zipfile|
        zipfile.add("database.dump", dump_path)
        zipfile.add("manifest.json", manifest_path)

        if include_files && Dir.exist?(uploads_dir)
          Dir.glob(File.join(uploads_dir, "**", "*")).select { |f| File.file?(f) }.each do |file|
            relative = file.sub("#{uploads_dir}/", "")
            zipfile.add(File.join("uploads", relative), file)
          end
        end
      end

      backup.update!(size: File.size(filepath))

      # 5. Encryption
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
    ensure
      FileUtils.rm_rf(tmp_dir) if Dir.exist?(tmp_dir)
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

    # Extract zip to tmp
    tmp_dir = Rails.root.join("tmp", "restore_#{backup.id}")
    FileUtils.mkdir_p(tmp_dir)

    begin
      Zip::File.open(filepath) do |zipfile|
        zipfile.extract("database.dump", File.join(tmp_dir, "database.dump"))
        if restore_files && zipfile.find_entry("manifest.json")
          zipfile.extract("manifest.json", File.join(tmp_dir, "manifest.json"))
        end
      end

      # 1. Restore database
      dump_path = File.join(tmp_dir, "database.dump")
      run_pg_restore(dump_path, backup)

      # 2. Restore files if present in zip
      if restore_files
        restored = restore_uploaded_files(filepath)
        backup.append_audit("files_restored", "#{restored} files")
      else
        backup.append_audit("files_manifest_restored", "No uploaded files in backup")
      end

      backup.append_audit("restore_completed")
      true
    ensure
      FileUtils.rm_rf(tmp_dir) if Dir.exist?(tmp_dir)
    end
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
    pg_dump_path = find_pg_dump

    env = {
      "PGPASSWORD" => db_config[:password].to_s,
      "PGSSLMODE" => db_config[:sslmode].to_s
    }

    command = [pg_dump_path, "-F", "c", "-f", filepath] + pg_connection_args(db_config)

    backup.append_audit("pg_dump_started")
    _stdout, stderr, status = Open3.capture3(env, *command)
    stderr = stderr.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")

    unless status.success?
      raise BackupError, "pg_dump failed: #{stderr.strip.presence || "exit status #{status.exitstatus}"}"
    end

    backup.append_audit("pg_dump_completed")
  end

  def self.run_pg_restore(filepath, backup)
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    pg_restore_path = find_pg_restore

    env = {
      "PGPASSWORD" => db_config[:password].to_s,
      "PGSSLMODE" => db_config[:sslmode].to_s
    }

    command = [pg_restore_path, "-c", "--if-exists", filepath] + pg_connection_args(db_config)

    backup.append_audit("pg_restore_started")
    _stdout, stderr, status = Open3.capture3(env, *command)
    stderr = stderr.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")

    unless status.success?
      raise RestoreError, "pg_restore failed: #{stderr.strip.presence || "exit status #{status.exitstatus}"}"
    end

    backup.append_audit("pg_restore_completed")
  end

  # Build the connection arguments for pg_dump/pg_restore. Neon requires the
  # endpoint ID to be passed explicitly when the client libpq lacks SNI
  # support (libpq < 15), otherwise it fails with "Endpoint ID is not specified".
  def self.pg_connection_args(db_config)
    host = db_config[:host] || "localhost"
    endpoint_id = neon_endpoint_id(host)

    if endpoint_id
      uri = URI::Generic.build(
        scheme: "postgres",
        userinfo: db_config[:username],
        host: host,
        port: (db_config[:port] || 5432).to_i,
        path: "/#{db_config[:database]}"
      )
      uri.query = "options=endpoint%3D#{endpoint_id}"
      ["-d", uri.to_s]
    else
      [
        "-h", host,
        "-p", (db_config[:port] || 5432).to_s,
        "-U", db_config[:username],
        "-d", db_config[:database]
      ]
    end
  end

  # Neon hosts look like "ep-fancy-name-123456.us-east-2.aws.neon.tech"; the
  # endpoint ID is everything before the first dot.
  def self.neon_endpoint_id(host)
    return nil unless host.to_s.match?(/\.neon\.tech\z/i)
    host.split(".").first
  end

  def self.restore_uploaded_files(zip_path)
    UPLOAD_DIRECTORIES.each do |dir|
      full_path = Rails.root.join(dir)
      FileUtils.mkdir_p(full_path)
    end

    restored = 0

    Zip::File.open(zip_path) do |zipfile|
      zipfile.each do |entry|
        name = entry.name.encode("UTF-8", invalid: :replace, undef: :replace)
        next unless name.start_with?("uploads/")
        next if entry.directory?

        relative = name.delete_prefix("uploads/")
        dest = Rails.root.join(relative.delete_prefix("/"))
        FileUtils.mkdir_p(File.dirname(dest))
        entry.extract(dest) { true } # force overwrite
        restored += 1
      end
    end

    restored
  end

  def self.find_pg_dump
    %w[pg_dump pg_dump.exe].each do |name|
      path = find_executable(name)
      return path if path
    end
    raise BackupError, "pg_dump not found. Install PostgreSQL and add its bin/ directory to PATH."
  end

  def self.find_pg_restore
    %w[pg_restore pg_restore.exe].each do |name|
      path = find_executable(name)
      return path if path
    end
    raise BackupError, "pg_restore not found. Install PostgreSQL and add its bin/ directory to PATH."
  end

  def self.find_executable(name)
    exts = Gem.win_platform? ? %w[.exe .cmd .bat] : [""]
    exts.each do |ext|
      cmd_name = name.end_with?(".exe", ".cmd", ".bat") ? name : "#{name}#{ext}"
      ENV["PATH"].to_s.split(File::PATH_SEPARATOR).each do |dir|
        full = File.join(dir, cmd_name)
        return full if File.executable?(full) && !File.directory?(full)
      end
    end

    if Gem.win_platform?
      %w[17 16 15 14 13].each do |ver|
        base = "C:/Program Files/PostgreSQL/#{ver}/bin"
        exts.each do |ext|
          full = File.join(base, "#{name}#{ext}")
          return full if File.exist?(full)
        end
      end
    end

    nil
  end

  def self.build_file_manifest(uploads_dir)
    manifest = { files: [], total_files: 0, total_size: 0 }
    root = Rails.root

    UPLOAD_DIRECTORIES.each do |dir|
      full_path = root.join(dir)
      next unless Dir.exist?(full_path)

      Dir.glob(File.join(full_path, "**", "*")).select { |f| File.file?(f) }.each do |file|
        relative = file.sub(root.to_s, "")
        size = File.size(file)

        # Copy file into zip staging area
        dest = File.join(uploads_dir, relative)
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(file, dest)

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
