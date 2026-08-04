# frozen_string_literal: true

class ExpireStalePendingSubscriptionsJob
  include Sidekiq::Job

  sidekiq_options queue: :subscriptions, retry: 2

  # Pending subscriptions without a provider_subscription_id that are older
  # than this threshold are considered abandoned and destroyed.
  STALE_THRESHOLD = 2.hours

  def perform
    stale = Subscription.where(status: "pending")
                        .where(provider_subscription_id: [nil, ""])
                        .where("created_at < ?", STALE_THRESHOLD.ago)

    count = stale.count
    return if count.zero?

    Rails.logger.info "Expiring #{count} stale pending subscriptions (older than #{STALE_THRESHOLD})"
    stale.find_each(&:destroy)
  end
end
