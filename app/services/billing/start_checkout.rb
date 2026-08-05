# frozen_string_literal: true

module Billing
  class StartCheckout
    def self.call(user:, provider_key:, return_url:)
      new(user:, provider_key:, return_url:).call
    end

    def initialize(user:, provider_key:, return_url:)
      @user = user
      @provider_key = provider_key
      @return_url = return_url
    end

    def call
      existing = @user.subscriptions.open.order(updated_at: :desc).first
      return [existing, { already_subscribed: true }] if existing&.access_active?
      if existing&.status == "pending" && existing.provider_subscription_id.present?
        url = existing.provider_metadata["checkout_url"]
        return [existing, { redirect_url: url, provider_subscription_id: existing.provider_subscription_id }] if url.present?
      end

      offering = Offering.current
      @new_record = existing.nil?

      ActiveRecord::Base.transaction do
        @subscription = existing || @user.subscriptions.create!(
          offering_key: offering.key, provider_key: @provider_key, status: "pending",
          amount_cents: offering.amount_cents, currency: offering.currency,
          interval_unit: offering.interval_unit, interval_count: offering.interval_count
        )
        provider = Subscriptions::Providers::Registry.build(@provider_key)
        action = provider.start_checkout(subscription: @subscription, return_url: @return_url)
        @subscription.update!(
          provider_subscription_id: action[:provider_subscription_id].presence || @subscription.provider_subscription_id,
          provider_metadata: @subscription.provider_metadata.merge("checkout_url" => action[:redirect_url])
        )
        [@subscription, action]
      end
    rescue StandardError => e
      if @new_record && @subscription&.persisted? && @subscription.status == "pending" && @subscription.provider_subscription_id.blank?
        @subscription.destroy
      end
      raise
    end
  end
end
