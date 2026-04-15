# frozen_string_literal: true

module Subscriptions
  class SyncPendingCheckoutJob
    include Sidekiq::Job
    sidekiq_options queue: :subscriptions, retry: 3, backtrace: true

    def perform(user_id, preapproval_id = nil)
      user = User.find_by(id: user_id)
      return unless user

      subscription = UserSubscription.find_by(user_id: user.id)
      return unless subscription

      provider = ::Subscriptions::Providers::Registry.current

      # If we have a preapproval_id, try to fetch it directly
      if preapproval_id.present?
        begin
          remote = provider.fetch_subscription!(subscription)
          sync_subscription_data(subscription, remote)
          return
        rescue => e
          Rails.logger.warn("Failed to sync with preapproval_id: #{e.message}")
        end
      end

      # Fallback: search for recent preapprovals by email
      sync_by_email_search(provider, subscription, user)
    end

    private

    def sync_subscription_data(subscription, remote)
      return unless remote.is_a?(Hash)

      status = remote["status"].to_s
      subscription.update!(
        provider: subscription.provider.presence || "mercado_pago",
        provider_subscription_id: remote["id"].to_s,
        provider_customer_id: remote.dig("payer_id")&.to_s || remote.dig("payer", "id")&.to_s || subscription.provider_customer_id,
        status: status,
        external_status: status,
        renews_at: remote.dig("auto_recurring", "next_payment_date").presence || subscription.renews_at,
        metadata: subscription.metadata.merge("polling_sync" => {
          synced_at: Time.zone.now.iso8601,
          status: status
        })
      )

      Rails.logger.info("Synced subscription #{subscription.id} for user #{subscription.user_id}")
    end

    def sync_by_email_search(provider, subscription, user)
      # Search MercadoPago API for recent preapprovals
      # This is a fallback when we don't have the preapproval_id
      access_token = SiteSetting.mercadopago_access_token
      return if access_token.blank?

      response = HTTParty.get(
        "https://api.mercadopago.com/preapproval/search",
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        },
        query: {
          payer_email: user.email,
          limit: 10,
          sort: "date_created",
          criteria: "desc"
        }
      )

      return unless response.code.between?(200, 299)

      parsed = JSON.parse(response.body)
      results = parsed["results"] || []

      # Find the most recent preapproval that matches our user
      recent_preapproval = results.find do |preapproval|
        # Check if it was created recently (last 10 minutes)
        created_at = Time.zone.parse(preapproval["date_created"]) rescue nil
        created_at && created_at > 10.minutes.ago &&
          (preapproval["external_reference"].to_s == user.id.to_s ||
           preapproval.dig("metadata", "user_id").to_s == user.id.to_s)
      end

      return unless recent_preapproval

      sync_subscription_data(subscription, recent_preapproval)
    end
  end
end
