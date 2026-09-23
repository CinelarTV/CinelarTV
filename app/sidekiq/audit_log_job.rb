# frozen_string_literal: true

class AuditLogJob
  include Sidekiq::Job

  sidekiq_options queue: :audit_log, retry: 3

  def perform(attrs_json)
    attrs = JSON.parse(attrs_json)
    AuditLog.create!(attrs)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[AuditLog] Failed to create audit log: #{e.message}")
  end
end
