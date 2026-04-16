# frozen_string_literal: true

namespace :backup do
  desc "Create a new database backup"
  task create: :environment do
    begin
      backup = BackupManager.create_backup(notes: ENV["NOTES"])
      puts "Backup created successfully: #{backup.filename}"
    rescue StandardError => e
      puts "Error creating backup: #{e.message}"
      exit 1
    end
  end

  desc "Restore a database backup (Usage: rake backup:restore[filename.dump])"
  task :restore, [:filename] => :environment do |_, args|
    filename = args[:filename]
    
    if filename.blank?
      puts "Error: You must specify a filename. Example: rake backup:restore[cinelar_backup_20260101.dump]"
      
      backups = Backup.order(created_at: :desc).limit(5)
      if backups.any?
        puts "\nRecent backups:"
        backups.each { |b| puts "- #{b.filename}" }
      end
      exit 1
    end

    force = ENV["FORCE"] == "true" || ENV["FORCE"] == "1"

    puts "WARNING: This will overwrite the current database with the contents of #{filename}."
    puts "Press Ctrl+C to cancel within 5 seconds..."
    sleep 5 unless force

    begin
      BackupManager.restore_backup(filename, force: force)
      puts "Restoration completed successfully."
    rescue BackupManager::RestoreDisabledError => e
      puts "Error: #{e.message}"
      puts "To force restoration via Rake, use FORCE=true"
    rescue StandardError => e
      puts "Error during restoration: #{e.message}"
      exit 1
    end
  end

  desc "List all available backups"
  task list: :environment do
    Backup.sync_with_disk
    backups = Backup.order(created_at: :desc)
    
    if backups.empty?
      puts "No backups found."
    else
      puts sprintf("%-40s | %-15s | %-20s", "Filename", "Size", "Date")
      puts "-" * 80
      backups.each do |b|
        size_str = ActionController::Base.helpers.number_to_human_size(b.size)
        puts sprintf("%-40s | %-15s | %-20s", b.filename, size_str, b.created_at.strftime("%Y-%m-%d %H:%M:%S"))
      end
    end
  end
end
