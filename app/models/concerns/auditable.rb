# frozen_string_literal: true

# Mixin for automatic model-level audit logging.
# Include in any model that should be tracked by the audit system.
#
# Usage:
#   class Content < ApplicationRecord
#     include Auditable
#   end
#
# This adds after_create, after_update, after_destroy callbacks
# that automatically log audit events via StaffActionLogger.
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create_commit :log_auditable_create
    after_update_commit :log_auditable_update
    after_destroy_commit :log_auditable_destroy
  end

  private

  def log_auditable_create
    return if is_a?(AuditLog)

    logger = build_audit_logger
    return unless logger

    method_name = "log_#{self.class.name.underscore}_create"
    if logger.respond_to?(method_name, true)
      logger.send(method_name, self)
    else
      logger.log_custom("#{self.class.name.underscore}.create", details: { id: id, title: try(:title) || try(:name) })
    end
  end

  def log_auditable_update
    return if is_a?(AuditLog)
    return unless saved_changes.any?

    logger = build_audit_logger
    return unless logger

    method_name = "log_#{self.class.name.underscore}_update"
    if logger.respond_to?(method_name, true)
      logger.send(method_name, self)
    else
      logger.log_custom("#{self.class.name.underscore}.update",
                        details: { id: id, changes: saved_changes.except("updated_at", "created_at") })
    end
  end

  def log_auditable_destroy
    return if is_a?(AuditLog)

    logger = build_audit_logger
    return unless logger

    method_name = "log_#{self.class.name.underscore}_delete"
    if logger.respond_to?(method_name, true)
      logger.send(method_name, self)
    else
      logger.log_custom("#{self.class.name.underscore}.destroy", details: { id: id, title: try(:title) || try(:name) })
    end
  end

  def build_audit_logger
    user = begin
      try(:current_user) || (respond_to?(:current_user, true) && current_user)
    rescue StandardError
      nil
    end
    return nil unless user

    StaffActionLogger.new(user)
  rescue ArgumentError
    nil
  end
end
