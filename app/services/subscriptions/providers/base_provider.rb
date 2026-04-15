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
        _repetitions: nil, _billing_day: nil, _billing_day_proportional: nil)
        raise NotImplementedError, "create_subscription! must be implemented"
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
        return "cancelled" if %w[cancelled canceled rejected refunded].include?(status)
        return "pending" if %w[pending in_process processing].include?(status)

        status
      end
    end
  end
end
