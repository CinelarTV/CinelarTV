# frozen_string_literal: true

# Responsible for logging admin/staff actions to the audit log.
# Pattern inspired by Discourse's StaffActionLogger.
class StaffActionLogger
  USER_FIELDS = %i[id username email created_at].freeze

  def initialize(admin)
    @admin = admin
    raise ArgumentError, "admin must be a User" unless @admin.is_a?(User)
  end

  # --- Settings ---

  def log_site_setting_change(setting_name, previous_value, new_value, opts = {})
    create_log(
      action: :change_site_setting,
      subject: setting_name.to_s,
      previous_value: previous_value&.to_s,
      new_value: new_value&.to_s,
      **opts
    )
  end

  # --- Users ---

  def log_user_suspend(user, reason: nil, until_time: nil, **)
    details = []
    details << "reason: #{reason}" if reason.present?
    details << "until: #{until_time.iso8601}" if until_time.present?

    create_log(
      action: :suspend_user,
      target_user: user,
      details: details.join("\n"),
      **
    )
  end

  def log_user_unsuspend(user, **)
    create_log(action: :unsuspend_user, target_user: user, **)
  end

  def log_user_deactivate(user, reason: nil, **)
    create_log(
      action: :deactivate_user,
      target_user: user,
      details: reason,
      **
    )
  end

  def log_user_activate(user, reason: nil, **)
    create_log(
      action: :activate_user,
      target_user: user,
      details: reason,
      **
    )
  end

  def log_user_deletion(deleted_user, **)
    details = USER_FIELDS.map { |f| "#{f}: #{deleted_user.public_send(f)}" }.join("\n")

    create_log(
      action: :delete_user,
      target_user: deleted_user,
      details: details,
      **
    )
  end

  def log_user_creation(user, **)
    create_log(
      action: :create_user,
      target_user: user,
      details: USER_FIELDS.map { |f| "#{f}: #{user.public_send(f)}" }.join("\n"),
      **
    )
  end

  def log_grant_admin(user, **)
    create_log(action: :grant_admin, target_user: user, **)
  end

  def log_revoke_admin(user, **)
    create_log(action: :revoke_admin, target_user: user, **)
  end

  # --- Content ---

  def log_content_create(content, **)
    create_log(
      action: :create_content,
      auditable: content,
      subject: content.try(:title),
      **
    )
  end

  def log_content_update(content, **)
    changes = content.previous_changes.except("updated_at", "created_at")
    create_log(
      action: :update_content,
      auditable: content,
      subject: content.try(:title),
      previous_value: format_changes(changes, :previous),
      new_value: format_changes(changes, :current),
      **
    )
  end

  def log_content_delete(content, **)
    create_log(
      action: :delete_content,
      auditable: content,
      subject: content.try(:title),
      **
    )
  end

  # --- Categories ---

  def log_category_create(category, **)
    create_log(
      action: :create_category,
      auditable: category,
      subject: category.try(:name),
      **
    )
  end

  def log_category_update(category, **)
    changes = category.previous_changes.except("updated_at", "created_at")
    create_log(
      action: :update_category,
      auditable: category,
      subject: category.try(:name),
      previous_value: format_changes(changes, :previous),
      new_value: format_changes(changes, :current),
      **
    )
  end

  def log_category_delete(category, **)
    create_log(
      action: :delete_category,
      auditable: category,
      subject: category.try(:name),
      **
    )
  end

  # --- Plugins ---

  def log_plugin_toggle(setting_name, new_value, **)
    create_log(
      action: :toggle_plugin,
      subject: setting_name.to_s,
      new_value: new_value.to_s,
      **
    )
  end

  # --- Backups ---

  def log_backup_create(backup, **)
    create_log(
      action: :create_backup,
      auditable: backup,
      subject: backup.try(:filename),
      **
    )
  end

  def log_backup_restore(backup, **)
    create_log(
      action: :restore_backup,
      auditable: backup,
      subject: backup.try(:filename),
      **
    )
  end

  def log_backup_delete(backup, **)
    create_log(
      action: :delete_backup,
      auditable: backup,
      subject: backup.try(:filename),
      **
    )
  end

  def log_backup_download(backup, **)
    create_log(
      action: :download_backup,
      auditable: backup,
      subject: backup.try(:filename),
      **
    )
  end

  # --- Subscriptions ---

  def log_grant_subscription(subscription, **)
    create_log(
      action: :grant_subscription,
      auditable: subscription,
      target_user: subscription.try(:user),
      **
    )
  end

  def log_cancel_subscription(subscription, **)
    create_log(
      action: :cancel_subscription,
      auditable: subscription,
      target_user: subscription.try(:user),
      **
    )
  end

  # --- Email ---

  def log_change_email_template(key, **)
    create_log(action: :change_email_template, subject: key, **)
  end

  def log_change_email_style(**)
    create_log(action: :change_email_style, **)
  end

  # --- Live TV ---

  def log_create_live_tv_channel(channel, **)
    create_log(
      action: :create_live_tv_channel,
      auditable: channel,
      subject: channel.try(:name),
      **
    )
  end

  def log_update_live_tv_channel(channel, **)
    create_log(
      action: :update_live_tv_channel,
      auditable: channel,
      subject: channel.try(:name),
      **
    )
  end

  def log_delete_live_tv_channel(channel, **)
    create_log(
      action: :delete_live_tv_channel,
      auditable: channel,
      subject: channel.try(:name),
      **
    )
  end

  # --- Video Sources ---

  def log_video_source_create(video_source, **)
    details = build_video_source_details(video_source)
    create_log(
      action: :create_video_source,
      auditable: video_source,
      subject: video_source.try(:url),
      details: details,
      **
    )
  end

  def log_video_source_update(video_source, **)
    changes = video_source.previous_changes.except("updated_at", "created_at")
    create_log(
      action: :update_video_source,
      auditable: video_source,
      subject: video_source.try(:url),
      previous_value: format_changes(changes, :previous),
      new_value: format_changes(changes, :current),
      **
    )
  end

  def log_video_source_delete(video_source, **)
    details = build_video_source_details(video_source)
    create_log(
      action: :delete_video_source,
      auditable: video_source,
      subject: video_source.try(:url),
      details: details,
      **
    )
  end

  # --- Generic / Custom (for plugins) ---

  def log_custom(custom_type, details: nil, **)
    create_log(
      action: :system_event,
      custom_type: custom_type,
      details: details.is_a?(Hash) ? details.map { |k, v| "#{k}: #{v}" }.join("\n") : details,
      **
    )
  end

  private

  def create_log(attrs = {})
    attrs[:user] = @admin
    attrs[:source] ||= "core"
    attrs[:ip_address] ||= extract_ip(attrs.delete(:request))
    attrs[:request_id] ||= extract_request_id(attrs.delete(:request))

    AuditLog.create!(attrs)
  end

  def extract_ip(request)
    return nil unless request.respond_to?(:remote_ip)

    request.remote_ip
  end

  def extract_request_id(request)
    return nil unless request.respond_to?(:request_id)

    request.request_id
  end

  def format_changes(changes, side)
    return nil if changes.empty?

    changes.map do |key, values|
      value = side == :previous ? values[0] : values[1]
      "#{key}: #{value}"
    end.join("\n")
  end

  def build_video_source_details(video_source)
    quality = video_source.try(:quality)
    format = video_source.try(:format)
    vtype = video_source.try(:videoable_type)
    vid = video_source.try(:videoable_id)
    "quality: #{quality}, format: #{format}, videoable: #{vtype}##{vid}"
  end
end
