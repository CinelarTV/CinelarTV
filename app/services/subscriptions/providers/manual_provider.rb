# frozen_string_literal: true

module Subscriptions
  module Providers
    class ManualProvider < BaseProvider
      def provider_key
        "manual"
      end

      def create_subscription!(user:, days: 30, **_extra)
        UserSubscription.create!(
          user: user,
          provider: "manual",
          status: "active",
          status_formatted: "Active",
          cancelled: false,
          granted_by_admin: true,
          granted_until: days.days.from_now,
          renews_at: days.days.from_now,
          ends_at: nil,
          external_status: "granted_by_admin"
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
