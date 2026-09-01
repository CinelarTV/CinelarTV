# frozen_string_literal: true

# Fast reconciliation for pending subscriptions that were recently created.
# Catches cases where the user closed the tab before the redirect completed
# and webhooks haven't fired yet.
class ReconcileRecentPendingJob
  include Sidekiq::Job
  extend MiniScheduler::Schedule

  sidekiq_options queue: :subscriptions, retry: 2

  every 2.minutes

  PENDING_THRESHOLD = 30.minutes

  def perform
    Subscription.where(status: "pending")
                .where.not(provider_subscription_id: [nil, ""])
                .where("created_at > ?", PENDING_THRESHOLD.ago)
                .find_each do |subscription|
      reconcile(subscription)
    rescue StandardError => e
      Rails.logger.warn("Recent pending reconcile failed #{subscription.id}: #{e.class}: #{e.message}")
    end
  end

  private

  def reconcile(subscription)
    provider = Subscriptions::Providers::Registry.build(subscription.provider_key)
    remote = provider.fetch_remote_subscription(subscription)
    return if remote.blank?

    Billing::RemoteSnapshot.apply!(subscription:, remote:)
  end
end
