# frozen_string_literal: true

module Admin
  class BackupsController < Admin::BaseController
    before_action :set_backup, only: %i[show destroy download verify restore]

    # GET /admin/backups
    def index
      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 20).to_i
      total = Backup.count
      @backups = Backup.order(created_at: :desc)
                        .offset((page - 1) * per_page)
                        .limit(per_page)

      render json: {
        data: @backups.map { |b| backup_json(b) },
        total: total,
        pages: (total.to_f / per_page).ceil
      }
    end

    # GET /admin/backups/:id
    def show
      render json: { data: backup_json(@backup, full: true) }
    end

    # POST /admin/backups
    def create
      notes = params[:notes]
      include_files = params.fetch(:include_files, true)
      encrypt = params.fetch(:encrypt, false)

      backup = BackupManager.create_backup(
        notes: notes,
        backup_type: "manual",
        include_files: include_files,
        encrypt: encrypt
      )

      render json: { data: backup_json(backup), message: "Backup created successfully" }, status: :created
    rescue BackupManager::BackupError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # POST /admin/backups/:id/restore
    def restore
      force = params.fetch(:force, false)
      restore_files = params.fetch(:restore_files, true)

      unless SiteSetting.allow_restore || force
        return render json: {
          error: "Restoration is disabled. Enable 'allow_restore' in Site Settings.",
          settings_path: "/admin/site_settings"
        }, status: :forbidden
      end

      @backup.append_audit("restore_requested", "user_id=#{current_user.id}")
      RestoreManager.restore(@backup.filename, force: force, restore_files: restore_files)

      render json: { message: "System restored successfully from #{@backup.filename}" }
    rescue RestoreManager::RestoreError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # GET /admin/backups/:id/download
    def download
      unless @backup.exist?
        return render json: { error: "Backup file not found on disk" }, status: :not_found
      end

      @backup.append_audit("downloaded", "user_id=#{current_user.id}")

      send_file @backup.path,
                filename: @backup.filename,
                type: "application/octet-stream",
                disposition: "attachment"
    end

    # POST /admin/backups/:id/verify
    def verify
      valid = @backup.verify_checksum!
      render json: {
        valid: valid,
        checksum: @backup.checksum,
        message: valid ? "Checksum verification passed" : "Checksum verification FAILED - file may be corrupted"
      }
    end

    # DELETE /admin/backups/:id
    def destroy
      @backup.append_audit("deleted", "user_id=#{current_user.id}")
      @backup.destroy_file!
      render json: { message: "Backup deleted" }
    end

    # POST /admin/backups/cleanup
    def cleanup
      cleaned = Backup.cleanup_expired!
      render json: { message: "Cleanup completed", cleaned_count: cleaned }
    end

    # GET /admin/backups/sync
    def sync
      Backup.sync_with_disk
      render json: { message: "Synced backups with disk" }
    end

    # GET /admin/backups/encryption_check
    def encryption_check
      configured = SiteSetting.backup_encryption_password.present?
      render json: { encryption_available: configured }
    end

    private

    def set_backup
      @backup = Backup.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Backup not found" }, status: :not_found
    end

    def backup_json(backup, full: false)
      data = {
        id: backup.id,
        filename: backup.filename,
        human_size: backup.human_size,
        size: backup.size,
        backup_type: backup.backup_type,
        status: backup.status,
        encrypted: backup.encrypted,
        source: backup.source,
        notes: backup.notes,
        created_at: backup.created_at,
        completed_at: backup.completed_at,
        expires_at: backup.expires_at,
        retention_days: backup.retention_days,
        checksum: backup.checksum&.truncate(16)
      }

      if full
        data[:audit_log] = backup.audit_log || []
        data[:file_manifest_summary] = {
          total_files: backup.file_manifest&.dig("total_files") || 0,
          total_size: backup.file_manifest&.dig("total_size") || 0
        }
        data[:error_message] = backup.error_message
      end

      data
    end
  end
end
