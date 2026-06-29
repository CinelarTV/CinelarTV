# frozen_string_literal: true

module Subscriptions
  module Providers
    class ManualProvider < BaseProvider
      def provider_key
        "manual"
      end

      def create_subscription!(user:, days: 30, trial_days: 0, **_extra)
        total_days = trial_days + days
        is_trialing = trial_days.positive?

        UserSubscription.create!(
          user: user,
          provider: "manual",
          status: is_trialing ? "trialing" : "active",
          status_formatted: is_trialing ? "Trial" : "Active",
          cancelled: false,
          granted_by_admin: true,
          granted_until: total_days.days.from_now,
          trial_ends_at: is_trialing ? trial_days.days.from_now : nil,
          renews_at: total_days.days.from_now,
          ends_at: nil,
          external_status: "granted_by_admin",
          metadata: { "manual_grant_days" => days, "trial_days" => trial_days }
        )
      end

      def fetch_subscription!(subscription)
        subscription.as_json
      end

      def cancel_subscription!(subscription)
        subscription.update!(
          cancelled: true,
          cancelled_at: Time.zone.now,
          status: "cancelled",
          status_formatted: "Cancelled",
          external_status: "cancelled_by_admin"
        )
      end

      def list_plans!
        raise NotImplementedError, "Manual provider has no plans"
      end

      def create_plan!(_params)
        raise NotImplementedError, "Manual provider has no plans"
      end

      def update_plan!(_plan_id, _params)
        raise NotImplementedError, "Manual provider has no plans"
      end

      def deactivate_plan!(_plan_id)
        raise NotImplementedError, "Manual provider has no plans"
      end
    end
  end
end
