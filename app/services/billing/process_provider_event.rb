# frozen_string_literal: true

module Billing
  class ProcessProviderEvent
    def self.call(event:, provider:)
      new(event:, provider:).call
    end

    def initialize(event:, provider:)
      @event = event
      @provider = provider
    end

    def call
      process_payment if payment_event?
      subscription = find_subscription
      return unless subscription

      remote = @provider.fetch_remote_subscription(subscription)
      return if remote.blank?

      RemoteSnapshot.apply!(subscription:, remote:)
    end

    private

    def find_subscription
      by_remote_id || by_correlation_id
    end

    def process_payment
      resource_id = @event.resource_id
      return if resource_id.blank?

      # Delegate payment recording to the provider if it has a payment fetch method
      return unless @provider.respond_to?(:fetch_payment, true)

      remote_payment = @provider.send(:fetch_payment, resource_id)
      return if remote_payment.blank?

      # Find subscription from the payment's reference to the subscription
      subscription = find_subscription_from_payment(remote_payment)
      return unless subscription

      record_payment(subscription, remote_payment)
    end

    def find_subscription_from_payment(remote_payment)
      # Try preapproval/subscription reference first
      sub_id = remote_payment["preapproval_id"].to_s.presence ||
               remote_payment["subscription_id"].to_s.presence
      return Subscription.find_by(provider_key: @event.provider_key, provider_subscription_id: sub_id) if sub_id.present?

      # Try external_reference (may be the Subscription UUID)
      external_ref = remote_payment["external_reference"].to_s
      return Subscription.find_by(id: external_ref) if external_ref.present?

      nil
    end

    def record_payment(subscription, remote_payment)
      status = case remote_payment["status"].to_s
               when "approved" then "succeeded"
               when "refunded", "charged_back" then "refunded"
               when "rejected", "cancelled" then "failed"
               else "pending"
               end

      payment = Payment.find_or_initialize_by(
        provider_key: @event.provider_key,
        provider_payment_id: remote_payment["id"].to_s
        )
      payment.assign_attributes(
        subscription:,
        user: subscription.user,
        kind: payment.persisted? ? payment.kind : "renewal",
        status:,
        amount_cents: (BigDecimal(remote_payment["transaction_amount"].to_s) * 100).round.to_i,
        currency: remote_payment["currency_id"].presence || subscription.currency,
        attempted_at: parse_time(remote_payment["date_created"]),
        paid_at: parse_time(remote_payment["date_approved"]),
        failure_code: remote_payment["status_detail"],
        provider_metadata: remote_payment.slice("operation_type", "payment_method_id", "status_detail")
      )
      payment.save!
    end

    def payment_event?
      @event.event_type.to_s.in?(%w[payment PAYMENT.SALE.COMPLETED])
    end

    def parse_time(value)
      return if value.blank?
      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def by_remote_id
      return if @event.resource_id.blank?
      Subscription.find_by(provider_key: @event.provider_key, provider_subscription_id: @event.resource_id)
    end

    def by_correlation_id
      correlation_id = @event.payload.dig("meta", "custom_data", "subscription_id") ||
        @event.payload["external_reference"]
      return if correlation_id.blank?

      subscription = Subscription.find_by(id: correlation_id)
      return unless subscription && subscription.provider_key == @event.provider_key

      if @event.resource_id.present? && subscription.provider_subscription_id.blank?
        subscription.update!(provider_subscription_id: @event.resource_id)
      end
      subscription
    end
  end
end
