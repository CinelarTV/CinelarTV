# frozen_string_literal: true

# Register core audit event types at boot.
# Plugins can register their own events in their plugin.rb after_initialize block.

Rails.application.config.after_initialize do
  # Settings
  AuditLog.register_event_type("change_site_setting", description: "Site setting changed", source: "core")

  # Users
  AuditLog.register_event_type("suspend_user", description: "User suspended", source: "core")
  AuditLog.register_event_type("unsuspend_user", description: "User unsuspended", source: "core")
  AuditLog.register_event_type("deactivate_user", description: "User deactivated", source: "core")
  AuditLog.register_event_type("activate_user", description: "User activated", source: "core")
  AuditLog.register_event_type("delete_user", description: "User deleted", source: "core")
  AuditLog.register_event_type("create_user", description: "User created", source: "core")
  AuditLog.register_event_type("grant_admin", description: "Admin role granted", source: "core")
  AuditLog.register_event_type("revoke_admin", description: "Admin role revoked", source: "core")

  # Content
  AuditLog.register_event_type("create_content", description: "Content created", source: "core")
  AuditLog.register_event_type("update_content", description: "Content updated", source: "core")
  AuditLog.register_event_type("delete_content", description: "Content deleted", source: "core")

  # Categories
  AuditLog.register_event_type("create_category", description: "Category created", source: "core")
  AuditLog.register_event_type("update_category", description: "Category updated", source: "core")
  AuditLog.register_event_type("delete_category", description: "Category deleted", source: "core")

  # Plugins
  AuditLog.register_event_type("toggle_plugin", description: "Plugin toggled", source: "core")

  # Backups
  AuditLog.register_event_type("create_backup", description: "Backup created", source: "core")
  AuditLog.register_event_type("restore_backup", description: "Backup restored", source: "core")
  AuditLog.register_event_type("delete_backup", description: "Backup deleted", source: "core")
  AuditLog.register_event_type("download_backup", description: "Backup downloaded", source: "core")

  # Subscriptions
  AuditLog.register_event_type("grant_subscription", description: "Subscription granted", source: "core")
  AuditLog.register_event_type("cancel_subscription", description: "Subscription cancelled", source: "core")

  # Email
  AuditLog.register_event_type("change_email_template", description: "Email template changed", source: "core")
  AuditLog.register_event_type("change_email_style", description: "Email style changed", source: "core")

  # Live TV
  AuditLog.register_event_type("create_live_tv_channel", description: "Live TV channel created", source: "core")
  AuditLog.register_event_type("update_live_tv_channel", description: "Live TV channel updated", source: "core")
  AuditLog.register_event_type("delete_live_tv_channel", description: "Live TV channel deleted", source: "core")

  # Video Sources
  AuditLog.register_event_type("create_video_source", description: "Video source created", source: "core")
  AuditLog.register_event_type("update_video_source", description: "Video source updated", source: "core")
  AuditLog.register_event_type("delete_video_source", description: "Video source deleted", source: "core")

  # System
  AuditLog.register_event_type("system_event", description: "System event (plugins)", source: "core")

  Rails.logger.info("[AuditLog] Registered #{AuditLog.registered_events.size} core event types")
end
