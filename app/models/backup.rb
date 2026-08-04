# frozen_string_literal: true

require "digest"
require "fileutils"

class Backup < ApplicationRecord
  BACKUP_TYPES = %w[manual scheduled].freeze
  STATUSES = %w[pending running completed failed].freeze

  validates :filename, presence: true, uniqueness: true
  validates :backup_type, inclusion: { in: BACKUP_TYPES }
  validates :status, inclusion: { in: STATUSES }

  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at < ?", Time.current) }
  scope :retained, -> { where("expires_at IS NULL OR expires_at >= ?", Time.current) }

  # --- Paths ---

  def path
    File.join(self.class.base_directory, filename)
  end

  def manifest_path
    path.sub(/\.zip$/, ".manifest.json")
  end

  def exist?
    File.exist?(path)
  end

  # --- Checksum ---

  def compute_checksum
    return nil unless exist?
    self.checksum = Digest::SHA256.file(path).hexdigest
    save! if persisted?
    checksum
  end

  def verify_checksum!
    return false unless exist? && checksum.present?
    actual = Digest::SHA256.file(path).hexdigest
    valid = actual == checksum
    append_audit("checksum_verify", valid ? "passed" : "failed")
    valid
  end

  # --- Audit ---

  def append_audit(action, detail = nil)
    entry = { action: action, timestamp: Time.current.iso8601, user_id: nil }
    entry[:detail] = detail if detail.present?
    self.audit_log = (audit_log || []) << entry
    save! if persisted?
  end

  # --- Encryption ---

  def encrypt_file!(password)
    return if encrypted? || !exist?

    encrypted_path = "#{path}.enc"
    system("openssl", "enc", "-aes-256-cbc", "-salt", "-pbkdf2",
           "-in", path, "-out", encrypted_path, "-pass", "pass:#{password}")
    return unless File.exist?(encrypted_path)

    FileUtils.mv(encrypted_path, path)
    self.encrypted = true
    self.encryption_key_fingerprint = Digest::SHA256.hexdigest(password)[0..15]
    save! if persisted?
    append_audit("encrypted")
  end

  def decrypt_file!(password)
    return unless encrypted? && exist?

    decrypted_path = "#{path}.dec"
    system("openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2",
           "-in", path, "-out", decrypted_path, "-pass", "pass:#{password}")
    return unless File.exist?(decrypted_path)

    FileUtils.mv(decrypted_path, path)
    self.encrypted = false
    save! if persisted?
    append_audit("decrypted")
  end

  # --- Size ---

  def human_size
    return "N/A" unless exist?
    bytes = File.size(path)
    if bytes >= 1.gigabyte
      "%.2f GB" % (bytes / 1.gigabyte.to_f)
    elsif bytes >= 1.megabyte
      "%.2f MB" % (bytes / 1.megabyte.to_f)
    else
      "%.2f KB" % (bytes / 1.kilobyte.to_f)
    end
  end

  # --- Retention ---

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def mark_completed!
    update!(status: "completed", completed_at: Time.current)
    compute_checksum
    append_audit("completed")
  end

  def mark_failed!(error)
    update!(status: "failed", error_message: error)
    append_audit("failed", error)
  end

  # --- Cleanup ---

  def destroy_file!
    FileUtils.rm_f(path) if exist?
    FileUtils.rm_f(manifest_path) if File.exist?(manifest_path)
    destroy!
  end

  # --- Class methods ---

  def self.base_directory
    @base_directory ||= Rails.root.join("storage", "backups")
  end

  def self.ensure_base_directory_exists!
    FileUtils.mkdir_p(base_directory) unless Dir.exist?(base_directory)
  end

  def self.cleanup_expired!
    expired.find_each do |backup|
      Rails.logger.info "Cleaning up expired backup: #{backup.filename}"
      backup.destroy_file!
    end
  end

  def self.sync_with_disk
    ensure_base_directory_exists!
    disk_files = Dir.glob(File.join(base_directory, "*.zip")).map { |f| File.basename(f) }
    db_files = Backup.pluck(:filename)

    (disk_files - db_files).each do |filename|
      path = File.join(base_directory, filename)
      Backup.create(
        filename: filename,
        size: File.size(path),
        backup_type: "manual",
        status: "completed",
        source: "disk_sync",
        created_at: File.mtime(path)
      )
    end
  end
end
