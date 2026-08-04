# frozen_string_literal: true

# Safety net for dropped or out-of-order provider notifications. Webhooks remain
# the fast path; this job only re-reads the provider's canonical resource.
class ReconcileSubscriptionsJob
  include Sidekiq::Job

  sidekiq_options queue: :subscriptions, retry: 3

  def perform
    Subscription.where(status: %w[pending active past_due cancelled])
      .where.not(provider_subscription_id: [nil, ""])
      .find_each do |subscription|
      reconcile(subscription)
    end
  end

  private

  def reconcile(subscription)
    provider = Subscriptions::Providers::Registry.build(subscription.provider_key)
    remote = provider.fetch_remote_subscription(subscription)
    return if remote.blank?

    Billing::RemoteSnapshot.apply!(subscription:, remote:)
  rescue StandardError => e
    Rails.logger.warn("Subscription reconciliation failed id=#{subscription.id} provider=#{subscription.provider_key}: #{e.class}: #{e.message}")
  end
end
