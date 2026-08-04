# frozen_string_literal: true

module Subscriptions
  module Providers
    class BaseProvider
      def provider_key
        raise NotImplementedError, "provider_key must be implemented"
      end

      def verify_webhook!(_request)
        true
      end

      def process_webhook!(_request)
        raise NotImplementedError, "process_webhook! must be implemented"
      end

      def create_subscription!(_user:, _success_url: nil, _failure_url: nil, _pending_url: nil, _checkout_mode: nil, _card_token_id: nil,
        _start_date: nil, _end_date: nil, _amount: nil, _currency_id: nil, _frequency: nil, _frequency_type: nil,
        _repetitions: nil, _billing_day: nil, _billing_day_proportional: nil, _purchase_token: nil, _product_id: nil,
        _package_name: nil, _store: nil)
        raise NotImplementedError, "create_subscription! must be implemented"
      end

      # New billing boundary. The legacy provider methods remain temporarily
      # behind this adapter so controllers never receive provider SDK objects.
      def start_checkout(subscription:, return_url:)
        checkout = create_subscription!(
          user: subscription.user,
          success_url: return_url,
          amount: subscription.amount_cents / 100.0,
          currency_id: subscription.currency,
          frequency: subscription.interval_count,
          frequency_type: "#{subscription.interval_unit}s",
          external_reference: subscription.id
        )
        {
          redirect_url: checkout.fetch(:checkout_url),
          provider_subscription_id: checkout[:preapproval_id],
          provider_customer_id: checkout[:customer_id],
          provider_plan_id: checkout[:plan_id]
        }
      end

      def fetch_remote_subscription(subscription)
        legacy = UserSubscription.new(provider_subscription_id: subscription.provider_subscription_id)
        fetch_subscription!(legacy)
      end

      def cancel(subscription)
        legacy = UserSubscription.new(
          provider: provider_key,
          provider_subscription_id: subscription.provider_subscription_id
        )
        cancel_subscription!(legacy) if subscription.provider_subscription_id.present?
      end

      def create_checkout!(_user:, _success_url: nil, _failure_url: nil, _pending_url: nil, _checkout_mode: nil, _card_token_id: nil,
        _start_date: nil, _end_date: nil, _amount: nil, _currency_id: nil, _frequency: nil, _frequency_type: nil,
        _repetitions: nil, _billing_day: nil, _billing_day_proportional: nil)
        create_subscription!(
          _user:,
          _success_url:,
          _failure_url:,
          _pending_url:,
          _checkout_mode:,
          _card_token_id:,
          _start_date:,
          _end_date:,
          _amount:,
          _currency_id:,
          _frequency:,
          _frequency_type:,
          _repetitions:,
          _billing_day:,
          _billing_day_proportional:
        )
      end

      def fetch_subscription!(_subscription)
        raise NotImplementedError, "fetch_subscription! must be implemented"
      end

      def cancel_subscription!(_subscription)
        raise NotImplementedError, "cancel_subscription! must be implemented"
      end

      def list_plans!
        raise NotImplementedError, "list_plans! must be implemented"
      end

      def create_plan!(_params)
        raise NotImplementedError, "create_plan! must be implemented"
      end

      def update_plan!(_plan_id, _params)
        raise NotImplementedError, "update_plan! must be implemented"
      end

      def deactivate_plan!(_plan_id)
        raise NotImplementedError, "deactivate_plan! must be implemented"
      end

      def get_subscription_status(subscription)
        remote = fetch_subscription!(subscription)
        return nil if remote.blank?

        normalize_status(remote["status"])
      rescue StandardError => e
        Rails.logger.warn("#{self.class.name}#get_subscription_status failed for subscription #{subscription&.id}: #{e.class} - #{e.message}")
        nil
      end

      def provider_metadata
        {
          provider_name: provider_key,
          provider_logo: nil,
          supported_regions: [],
          checkout_type: "redirect"
        }
      end

      # Converts the raw Hash returned by fetch_subscription! into a safe set of
      # model attributes for UserSubscription#update!.
      # Subclasses should override this to map provider-specific fields.
      # The default implementation is a no-op safe guard — returns only status.
      def normalize_remote_for_update(subscription, remote)
        raw_status = remote["status"].to_s
        {
          status:         normalize_status(raw_status),
          external_status: raw_status,
          metadata:       subscription.metadata.merge("remote_sync" => remote, "synced_at" => Time.zone.now.iso8601)
        }.compact
      end

      protected

      def parse_time(value)
        return nil if value.blank?

        Time.zone.parse(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end

      def normalize_status(value)
        return "inactive" if value.blank?

        status = value.to_s.downcase

        return "active" if %w[approved active authorized paid].include?(status)
        return "trialing" if %w[trialing trial trial_active].include?(status)
        return "cancelled" if %w[cancelled canceled rejected refunded].include?(status)
        return "pending" if %w[pending in_process processing].include?(status)
        return "past_due" if %w[past_due unpaid].include?(status)

        status
      end
    end
  end
end
