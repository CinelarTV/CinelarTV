# frozen_string_literal: true

module Billing
  class RemoteSnapshot
    def self.apply!(subscription:, remote:)
      status = normalize_status(remote["status"])
      recurring = remote["auto_recurring"] || {}
      period_end = parse_time(
        remote["renews_at"] || remote["ends_at"] || recurring["next_payment_date"] || recurring["end_date"]
      )
      SubscriptionTransition.apply!(
        subscription:,
        status:,
        period_start: parse_time(remote["current_period_start"]),
        period_end:,
        remote_updated_at: parse_time(remote["updated_at"] || remote["last_modified"]),
        metadata: { "remote_status" => remote["status"], "last_remote_sync" => Time.current.iso8601 }
      )
    end

    def self.normalize_status(value)
      case value.to_s.downcase
      when "active", "approved", "authorized", "paid" then "active"
      when "past_due", "unpaid", "overdue" then "past_due"
      when "cancelled", "canceled" then "cancelled"
      when "expired", "inactive" then "expired"
      else "pending"
      end
    end

    def self.parse_time(value)
      return if value.blank?
      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
    private_class_method :parse_time
  end
end
