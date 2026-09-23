# frozen_string_literal: true

class AuditLog < ApplicationRecord
  # --- Extensible Event Type Registry (thread-safe for Sidekiq) ---
  EVENT_REGISTRY = Concurrent::Map.new

  # Actions enum — integer-backed, extensible via custom_type for plugins
  enum :action, {
    # Settings
    change_site_setting: 0,

    # Users
    suspend_user: 10,
    unsuspend_user: 11,
    deactivate_user: 12,
    activate_user: 13,
    delete_user: 14,
    create_user: 15,
    grant_admin: 16,
    revoke_admin: 17,

    # Content
    create_content: 30,
    update_content: 31,
    delete_content: 32,

    # Categories
    create_category: 40,
    update_category: 41,
    delete_category: 42,

    # Plugins
    toggle_plugin: 50,

    # Backups
    create_backup: 60,
    restore_backup: 61,
    delete_backup: 62,
    download_backup: 63,

    # Subscriptions
    grant_subscription: 70,
    cancel_subscription: 71,

    # Email
    change_email_template: 80,
    change_email_style: 81,

    # Live TV
    create_live_tv_channel: 85,
    update_live_tv_channel: 86,
    delete_live_tv_channel: 87,

    # Video Sources
    create_video_source: 88,
    update_video_source: 89,
    delete_video_source: 90,

    # System
    system_event: 99
  }, prefix: :action

  # Associations
  belongs_to :user, optional: true
  belongs_to :target_user, class_name: "User", optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  # Validations
  validates :action, presence: true
  validates :source, presence: true, length: { maximum: 100 }
  validates :result, inclusion: { in: %w[success failure error] }
  validates :ip_address, length: { maximum: 45 }, allow_nil: true
  validates :request_id, length: { maximum: 36 }, allow_nil: true

  # Scopes
  scope :by_user, ->(user) { where(user: user) }
  scope :by_target_user, ->(user) { where(target_user: user) }
  scope :by_action_type, ->(action_name) { where(action: action_name) }
  scope :by_source, ->(source) { where(source: source) }
  scope :by_auditable, ->(type, id) { where(auditable_type: type, auditable_id: id) }
  scope :since, ->(date) { where("created_at >= ?", date) }
  scope :before, ->(date) { where("created_at <= ?", date) }
  scope :recent, ->(limit = 50) { order(created_at: :desc).limit(limit) }

  # --- Registry Methods ---

  def self.register_event_type(name, description: nil, source: "core")
    EVENT_REGISTRY[name] = { description: description, source: source }
  end

  def self.registered_events
    result = {}
    EVENT_REGISTRY.each_pair { |k, v| result[k] = v }
    result
  end

  def self.custom_actions
    where(action: :system_event).distinct.pluck(:custom_type).compact
  end

  # --- Cleanup ---
  def self.cleanup_old!(days: nil)
    days ||= SiteSetting.respond_to?(:audit_log_retention_days) ? SiteSetting.audit_log_retention_days : 90
    where("created_at < ?", days.days.ago).in_batches(of: 10_000).delete_all
  end

  # --- Human-readable action name ---
  ACTION_LABELS = {
    "change_site_setting" => "cambiar configuración del sitio",
    "suspend_user" => "suspender usuario",
    "unsuspend_user" => "quitar suspensión",
    "deactivate_user" => "desactivar usuario",
    "activate_user" => "activar usuario",
    "delete_user" => "eliminar usuario",
    "create_user" => "crear usuario",
    "grant_admin" => "otorgar admin",
    "revoke_admin" => "revocar admin",
    "create_content" => "crear contenido",
    "update_content" => "actualizar contenido",
    "delete_content" => "eliminar contenido",
    "create_category" => "crear categoría",
    "update_category" => "actualizar categoría",
    "delete_category" => "eliminar categoría",
    "toggle_plugin" => "alternar plugin",
    "create_backup" => "crear backup",
    "restore_backup" => "restaurar backup",
    "delete_backup" => "eliminar backup",
    "download_backup" => "descargar backup",
    "grant_subscription" => "otorgar suscripción",
    "cancel_subscription" => "cancelar suscripción",
    "change_email_template" => "cambiar plantilla de email",
    "change_email_style" => "cambiar estilo de email",
    "create_live_tv_channel" => "crear canal TV en vivo",
    "update_live_tv_channel" => "actualizar canal TV en vivo",
    "delete_live_tv_channel" => "eliminar canal TV en vivo",
    "create_video_source" => "crear fuente de video",
    "update_video_source" => "actualizar fuente de video",
    "delete_video_source" => "eliminar fuente de video",
    "system_event" => "evento del sistema"
  }.freeze

  def human_action
    ACTION_LABELS[action] || action.humanize
  end

  def description_for_user
    parts = [human_action]
    parts << subject if subject.present?
    parts.join(" ")
  end
end
