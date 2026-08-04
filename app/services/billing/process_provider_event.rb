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
      return unless @event.provider_key == "mercado_pago" && @event.resource_id.present?

      remote = @provider.send(:fetch_payment, @event.resource_id)
      preapproval_id = remote["preapproval_id"].to_s
      subscription = Subscription.find_by(provider_key: @event.provider_key, provider_subscription_id: preapproval_id)
      return unless subscription

      status = case remote["status"].to_s
               when "approved" then "succeeded"
               when "refunded" then "refunded"
               when "rejected", "cancelled" then "failed"
               else "pending"
               end
      payment = Payment.find_or_initialize_by(provider_key: @event.provider_key, provider_payment_id: remote["id"].to_s)
      payment.assign_attributes(
        subscription:, user: subscription.user, kind: payment.persisted? ? payment.kind : "renewal", status:,
        amount_cents: (BigDecimal(remote["transaction_amount"].to_s) * 100).round.to_i,
        currency: remote["currency_id"].presence || subscription.currency,
        attempted_at: parse_time(remote["date_created"]), paid_at: parse_time(remote["date_approved"]),
        failure_code: remote["status_detail"], provider_metadata: remote.slice("operation_type", "payment_method_id", "status_detail")
      )
      payment.save!
    end

    def payment_event?
      @event.event_type.to_s == "payment"
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
