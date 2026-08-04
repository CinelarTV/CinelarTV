# frozen_string_literal: true

module Billing
  class SubscriptionTransition
    # All provider-specific status mapping must happen before this boundary.
    def self.apply!(subscription:, status:, period_start: nil, period_end: nil, remote_updated_at: nil, metadata: {})
      raise ArgumentError, "Unsupported subscription state: #{status}" unless Subscription::STATUSES.include?(status)

      subscription.with_lock do
        return subscription if stale?(subscription, remote_updated_at)

        attributes = {
          status: status,
          remote_updated_at: remote_updated_at || subscription.remote_updated_at,
          last_reconciled_at: Time.current,
          provider_metadata: subscription.provider_metadata.merge(metadata)
        }
        attributes[:current_period_started_at] = period_start if period_start
        attributes[:current_period_ends_at] = period_end if period_end

        case status
        when "active"
          attributes[:access_until] = period_end if period_end
          attributes[:grace_ends_at] = nil
          attributes[:cancelled_at] = nil
        when "past_due"
          # Product policy, deliberately independent from a provider retry schedule.
          attributes[:grace_ends_at] ||= [subscription.access_until, Time.current].compact.max + 7.days
          attributes[:access_until] = attributes[:grace_ends_at]
        when "cancelled"
          attributes[:cancelled_at] ||= Time.current
          attributes[:cancel_at_period_end] = true
        when "expired"
          attributes[:expired_at] ||= Time.current
          attributes[:access_until] = [subscription.access_until, Time.current].compact.min
        end
        subscription.update!(attributes)
      end
    end

    def self.stale?(subscription, timestamp)
      timestamp.present? && subscription.remote_updated_at.present? && timestamp < subscription.remote_updated_at
    end
    private_class_method :stale?
  end
end
