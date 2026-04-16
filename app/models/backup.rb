# frozen_string_literal: true

class Backup < ApplicationRecord
  validates :filename, presence: true, uniqueness: true

  def path
    File.join(self.class.base_directory, filename)
  end

  def exist?
    File.exist?(path)
  end

  def self.base_directory
    @base_directory ||= Rails.root.join("storage", "backups")
  end

  def self.ensure_base_directory_exists!
    FileUtils.mkdir_p(base_directory) unless Dir.exist?(base_directory)
  end

  def self.all_files
    ensure_base_directory_exists!
    Dir.glob(File.join(base_directory, "*.dump")).map { |f| File.basename(f) }
  end

  def self.sync_with_disk
    disk_files = all_files
    db_files = Backup.pluck(:filename)

    # Add missing files to DB
    (disk_files - db_files).each do |filename|
      path = File.join(base_directory, filename)
      Backup.create(
        filename: filename,
        size: File.size(path),
        backup_type: "manual",
        source: "disk_sync",
        created_at: File.mtime(path)
      )
    end

    # (Optional) Remove DB records if files don't exist? 
    # Usually better to keep the record but mark as missing.
  end
end
