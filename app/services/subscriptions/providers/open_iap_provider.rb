# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Subscriptions
  module Providers
    class OpenIapProvider < BaseProvider
      def provider_key
        "open_iap"
      end

      def verify_webhook!(_request)
        true
      end

      def process_webhook!(_request)
        true
      end

      def create_subscription!(user:, success_url: nil, failure_url: nil, pending_url: nil, checkout_mode: nil, card_token_id: nil,
        start_date: nil, end_date: nil, amount: nil, currency_id: nil, frequency: nil, frequency_type: nil,
        repetitions: nil, billing_day: nil, billing_day_proportional: nil, purchase_token: nil, product_id: nil, package_name: nil, store: nil)
        if purchase_token.present? && product_id.present?
          create_subscription_from_token!(user: user, product_id: product_id, purchase_token: purchase_token, store: store)
        else
          raise ArgumentError, "purchase_token and product_id are required for OpenIAP subscription creation"
        end
      end

      def fetch_subscription!(subscription)
        purchase_token = subscription.purchase_token
        product_id = subscription.iap_product_id

        if purchase_token.blank? || product_id.blank?
          Rails.logger.warn("#{self.class.name}#fetch_subscription!: missing purchase_token or product_id for subscription #{subscription.id}")
          return nil
        end

        verify_purchase(product_id: product_id, purchase_token: purchase_token, store: subscription.metadata['store'])
      end

      def cancel_subscription!(_subscription)
        true
      end

      # Associates a userId with a tracked subscription in Kit via POST /v1/subscriptions/bind-user/{apiKey}.
      # This enables the sync job to find subscriptions by userId.
      def bind_user!(purchase_token:, user_id:)
        base_url = SiteSetting.open_iap_base_url.to_s.presence || "https://kit.openiap.dev"
        api_key = SiteSetting.open_iap_api_key.to_s
        return if api_key.blank? || purchase_token.blank? || user_id.blank?

        url = URI.parse("#{base_url}/v1/subscriptions/bind-user/#{api_key}")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = url.scheme == "https"
        http.open_timeout = 10
        http.read_timeout = 15

        req = Net::HTTP::Post.new(url.request_uri)
        req['Content-Type'] = 'application/json'
        req.body = { purchaseToken: purchase_token, userId: user_id.to_s }.to_json

        resp = http.request(req)

        if resp.code.to_i >= 200 && resp.code.to_i < 300
          Rails.logger.info("#{self.class.name}: Bound userId=#{user_id} to token=#{purchase_token&.truncate(20)}")
        else
          Rails.logger.warn("#{self.class.name}: bind-user failed HTTP #{resp.code}: #{resp.body}")
        end
      rescue StandardError => e
        Rails.logger.error("#{self.class.name}: bind-user error: #{e.class} — #{e.message}")
      end

      def list_plans!
        product_map = SiteSetting.open_iap_product_id_map
        return [] if product_map.blank?

        parsed = product_map.is_a?(String) ? (JSON.parse(product_map) rescue {}) : product_map
        parsed.map do |product_id, plan_name|
          { id: product_id, name: plan_name, product_id: product_id }
        end
      end

      def normalize_remote_for_update(subscription, remote)
        state = remote["state"].to_s
        raw_status = state

        status = case state
        when "ENTITLED", "PENDING_ACKNOWLEDGMENT", "READY_TO_CONSUME"
          "active"
        when "CANCELED", "EXPIRED", "INAUTHENTIC", "REVOKED", "REFUNDED"
          "cancelled"
        when "PENDING", "CONSUMED"
          "pending"
        else
          "active"
        end

        {
          status: status,
          status_formatted: status.humanize,
          external_status: raw_status,
          metadata: subscription.metadata.merge(
            "remote_sync" => remote,
            "synced_at" => Time.zone.now.iso8601,
            "open_iap_state" => state,
            "store" => remote["store"]
          )
        }.compact
      end

      protected

      def create_subscription_from_token!(user:, product_id:, purchase_token:, store: nil)
        remote = verify_purchase(product_id: product_id, purchase_token: purchase_token, store: store)
        raise StandardError, "OpenIAP verification failed: #{remote&.inspect}" if remote.blank?
        raise StandardError, "Purchase is not valid (isValid=#{remote['isValid']})" unless remote['isValid']

        subscription = user.user_subscriptions.find_or_initialize_by(purchase_token: purchase_token)
        subscription.iap_product_id = product_id
        subscription.provider = provider_key
        subscription.metadata['store'] = store || detect_store(remote)
        subscription.assign_attributes(normalize_remote_for_update(subscription, remote))
        subscription.user_id ||= user.id if user.respond_to?(:id)
        subscription.save!

        # Bind userId in Kit so the sync job can find this subscription
        bind_user!(purchase_token: purchase_token, user_id: user.id)

        {
          subscription: subscription.as_json,
          plan_id: subscription.provider_plan_id,
          checkout_url: nil,
          checkout_mode: 'in_app',
          provider: provider_key
        }
      end

      def verify_purchase(product_id:, purchase_token:, store: nil)
        base_url = SiteSetting.open_iap_base_url.to_s.presence || "https://kit.openiap.dev"
        api_key = SiteSetting.open_iap_api_key.to_s
        return nil if api_key.blank?

        store ||= detect_store_from_product(product_id)

        url = URI.parse("#{base_url}/v1/purchase/verify")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = url.scheme == "https"
        http.open_timeout = 10
        http.read_timeout = 30

        req = Net::HTTP::Post.new(url.request_uri)
        req['Content-Type'] = 'application/json'
        req['Authorization'] = "Bearer #{api_key}"
        req.body = { store: store, purchaseToken: purchase_token }.to_json

        resp = http.request(req)

        if resp.code.to_i >= 200 && resp.code.to_i < 300
          JSON.parse(resp.body) rescue nil
        else
          Rails.logger.error("#{self.class.name}#verify_purchase HTTP #{resp.code}: #{resp.body}")
          nil
        end
      rescue StandardError => e
        Rails.logger.error("#{self.class.name}#verify_purchase error: #{e.class} - #{e.message}")
        nil
      end

      def detect_store(remote)
        raw = remote["store"].to_s.presence || detect_store_from_product(remote["productId"])
        raw
      end

      def detect_store_from_product(product_id)
        return "google" if product_id.to_s.start_with?("com.")
        return "apple" if product_id.to_s.match?(/\A\d+\z/)

        "google"
      end
    end
  end
end
