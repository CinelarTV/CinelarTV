# frozen_string_literal: true

module Billing
  class RemoteSnapshot
    def self.apply!(subscription:, remote:, metadata: {})
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
        metadata: { "remote_status" => remote["status"], "last_remote_sync" => Time.current.iso8601 }.merge(metadata)
      )

      record_last_payment(subscription:, remote:) if status == "active"
    end

    def self.record_last_payment(subscription:, remote:)
      last_payment = remote["last_payment"]
      return if last_payment.blank?

      amount = last_payment["amount"]
      currency = last_payment["currency"]
      paid_at = parse_time(last_payment["date"])
      return if amount.blank? || paid_at.blank?

      amount_cents = (BigDecimal(amount.to_s) * 100).round.to_i rescue nil
      return if amount_cents.nil?

      payment_exists = Payment.exists?(subscription_id: subscription.id, paid_at: paid_at.beginning_of_hour..paid_at.end_of_hour)
      return if payment_exists

      Payment.create!(
        subscription: subscription,
        user: subscription.user,
        provider_key: subscription.provider_key,
        provider_payment_id: "#{subscription.provider_subscription_id}_#{paid_at.to_i}",
        kind: "initial",
        status: "succeeded",
        amount_cents: amount_cents,
        currency: currency || subscription.currency,
        paid_at: paid_at,
        attempted_at: paid_at,
        provider_metadata: { "source" => "remote_snapshot_sync" }
      )
    rescue StandardError => e
      Rails.logger.warn("Failed to record payment from snapshot: #{e.message}")
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
