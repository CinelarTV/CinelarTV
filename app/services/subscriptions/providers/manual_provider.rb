# frozen_string_literal: true

module Subscriptions
  module Providers
    class ManualProvider < BaseProvider
      def provider_key
        "manual"
      end

      def start_checkout(subscription:, return_url:)
        grant_days = subscription.provider_metadata["grant_days"] || 30
        trial_days = subscription.provider_metadata["trial_days"] || 0
        total_days = trial_days + grant_days
        is_trialing = trial_days.positive?

        period_end = total_days.days.from_now

        SubscriptionTransition.apply!(
          subscription:,
          status: "active",
          period_start: Time.current,
          period_end:,
          remote_updated_at: Time.current,
          metadata: {
            "manual_grant" => true,
            "grant_days" => grant_days,
            "trial_days" => trial_days
          }
        )

        {
          redirect_url: return_url,
          provider_subscription_id: "manual_#{subscription.id}",
          provider_customer_id: nil,
          provider_plan_id: "manual"
        }
      end

      def fetch_remote_subscription(subscription)
        {
          "status" => subscription.status,
          "id" => subscription.provider_subscription_id,
          "current_period_start" => subscription.current_period_started_at&.iso8601,
          "current_period_ends_at" => subscription.current_period_ends_at&.iso8601
        }
      end

      def cancel(subscription)
        SubscriptionTransition.apply!(
          subscription:,
          status: "cancelled",
          remote_updated_at: Time.current,
          metadata: { "cancelled_by" => "admin" }
        )
      end

      def list_plans!
        { "results" => [] }
      end

      def create_plan!(_params)
        raise "Manual provider has no plans"
      end

      def update_plan!(_plan_id, _params)
        raise "Manual provider has no plans"
      end

      def deactivate_plan!(_plan_id)
        raise "Manual provider has no plans"
      end
    end
  end
end
