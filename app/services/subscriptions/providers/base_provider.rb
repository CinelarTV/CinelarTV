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

      def create_checkout!(_user:, _success_url: nil, _failure_url: nil, _pending_url: nil)
        raise NotImplementedError, "create_checkout! must be implemented"
      end

      def fetch_subscription!(_subscription)
        raise NotImplementedError, "fetch_subscription! must be implemented"
      end

      def cancel_subscription!(_subscription)
        raise NotImplementedError, "cancel_subscription! must be implemented"
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
