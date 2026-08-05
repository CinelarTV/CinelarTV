# frozen_string_literal: true

require "base64"
require "json"
require "jwt"
require "net/http"
require "openssl"
require "uri"

module Subscriptions
  module Providers
    class GooglePlayProvider < BaseProvider
      TOKEN_URI = "https://oauth2.googleapis.com/token"
      API_ROOT = "https://androidpublisher.googleapis.com/androidpublisher/v3"
      PUBSUB_CERTS_URI = "https://www.googleapis.com/oauth2/v3/certs"
      ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher"

      NOTIFICATION_TYPES = {
        1 => "recovered",
        2 => "renewed",
        3 => "canceled",
        4 => "purchased",
        5 => "on_hold",
        6 => "in_grace_period",
        7 => "restarted",
        8 => "price_change_confirmed",
        9 => "deferred",
        10 => "paused",
        11 => "pause_schedule_changed",
        12 => "revoked",
        13 => "expired",
        20 => "pending_purchase_canceled"
      }.freeze

      def provider_key
        "google_play"
      end

      def verify_webhook!(request)
        return true unless SiteSetting.google_play_pubsub_verify_oidc

        token = bearer_token(request)
        return false if token.blank?

        verify_pubsub_oidc_token!(token)
        true
      rescue StandardError => e
        Rails.logger.warn("#{self.class.name} Pub/Sub OIDC verification failed: #{e.class} - #{e.message}")
        false
      end

      def process_webhook!(request)
        payload = parse_json(request.raw_post)
        notification = decode_pubsub_notification(payload)

        if notification.blank?
          Rails.logger.warn("#{self.class.name}: Pub/Sub payload did not contain a Google Play notification")
          return
        end

        sub_notification = notification["subscriptionNotification"] || {}
        purchase_token = sub_notification["purchaseToken"].to_s
        product_id = sub_notification["subscriptionId"].to_s
        package_name = notification["packageName"].to_s

        if purchase_token.blank? || product_id.blank?
          Rails.logger.info("#{self.class.name}: Ignoring non-subscription notification #{notification.inspect}")
          return
        end

        ensure_expected_package!(package_name) if package_name.present?
        ensure_expected_product!(product_id)

        # Find subscription by purchase_token stored in provider_metadata
        subscription = Subscription.where(provider_key: provider_key)
          .where("provider_metadata->>'purchase_token' = ?", purchase_token)
          .first

        if subscription.blank?
          Rails.logger.warn("#{self.class.name}: No local subscription for token=#{purchase_token.truncate(20)} product=#{product_id}")
          return
        end

        remote = verify_purchase(product_id: product_id, purchase_token: purchase_token)
        return if remote.blank?

        event_type = notification_type_name(sub_notification["notificationType"])
        Billing::RemoteSnapshot.apply!(
          subscription:,
          remote:,
          metadata: {
            "last_google_play_event" => event_type,
            "last_google_play_event_at" -> Time.zone.now.iso8601,
            "last_google_play_notification" => notification
          }
        )
      end

      def start_checkout(subscription:, return_url:)
        purchase_token = subscription.provider_metadata["purchase_token"]
        product_id = subscription.provider_metadata["product_id"] || selected_product_id

        raise ArgumentError, "purchase_token is required for Google Play subscriptions" if purchase_token.blank?
        raise ArgumentError, "product_id is required for Google Play subscriptions" if product_id.blank?

        ensure_expected_product!(product_id)
        ensure_expected_package!(package_name)

        remote = verify_purchase(product_id: product_id, purchase_token: purchase_token)
        raise StandardError, "Google Play verification failed" if remote.blank?

        # Update subscription with Google Play identifiers
        subscription.update!(
          provider_subscription_id: remote["latestOrderId"].presence || purchase_token,
          provider_plan_id: product_id,
          provider_metadata: subscription.provider_metadata.merge(
            "purchase_token" => purchase_token,
            "product_id" => product_id
          )
        )

        # Apply remote state
        Billing::RemoteSnapshot.apply!(subscription:, remote:)

        {
          redirect_url: nil,
          provider_subscription_id: subscription.provider_subscription_id,
          provider_customer_id: nil,
          provider_plan_id: product_id
        }
      end

      def fetch_remote_subscription(subscription)
        purchase_token = subscription.provider_metadata["purchase_token"]
        product_id = subscription.provider_plan_id

        return nil if purchase_token.blank? || product_id.blank?

        verify_purchase(product_id: product_id, purchase_token: purchase_token)
      end

      def cancel(_subscription)
        raise "Google Play subscriptions must be cancelled by the user in Google Play"
      end

      def list_plans!(managed_only: true)
        product_id = selected_product_id
        return { "results" => [] } if product_id.blank?

        {
          "results" => [
            {
              "id" => product_id,
              "product_id" => product_id,
              "reason" => "Google Play",
              "name" => "Google Play",
              "auto_recurring" => {}
            }
          ]
        }
      end

      def create_plan!(_params)
        raise "Google Play products must be managed in Google Play Console"
      end

      def update_plan!(_plan_id, _params)
        raise "Google Play products must be managed in Google Play Console"
      end

      def deactivate_plan!(_plan_id)
        raise "Google Play products must be managed in Google Play Console"
      end

      def verify_purchase(product_id:, purchase_token:)
        ensure_expected_product!(product_id)

        package = package_name
        raise "Google Play package name is missing" if package.blank?

        url = URI.parse("#{API_ROOT}/applications/#{URI.encode_www_form_component(package)}/purchases/subscriptionsv2/tokens/#{URI.encode_www_form_component(purchase_token)}")
        req = Net::HTTP::Get.new(url.request_uri)
        req["Authorization"] = "Bearer #{access_token}"
        req["Accept"] = "application/json"

        resp = perform_http(url, req)
        if resp.code.to_i == 404
          raise ActiveRecord::RecordNotFound, "Google Play subscription token not found"
        end
        unless resp.code.to_i.between?(200, 299)
          Rails.logger.error("#{self.class.name} verify_purchase HTTP #{resp.code}: #{resp.body}")
          return nil
        end

        parse_json(resp.body)
      rescue ActiveRecord::RecordNotFound
        raise
      rescue StandardError => e
        Rails.logger.error("#{self.class.name} verify_purchase failed: #{e.class} - #{e.message}")
        nil
      end

      private

      def selected_product_id
        SiteSetting.google_play_subscription_product_id.to_s.strip.presence
      end

      def package_name
        SiteSetting.google_play_package_name.to_s.strip
      end

      def ensure_expected_product!(product_id)
        expected = selected_product_id
        raise "Google Play subscription product id is missing" if expected.blank?
        raise ArgumentError, "Unexpected Google Play product id" if product_id.to_s != expected
      end

      def ensure_expected_package!(value)
        expected = package_name
        raise "Google Play package name is missing" if expected.blank?
        raise ArgumentError, "Unexpected Google Play package name" if value.to_s != expected
      end

      def normalize_google_play_state(value)
        case value.to_s
        when "SUBSCRIPTION_STATE_ACTIVE"
          "active"
        when "SUBSCRIPTION_STATE_PENDING"
          "pending"
        when "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"
          "active"
        when "SUBSCRIPTION_STATE_ON_HOLD", "SUBSCRIPTION_STATE_PAUSED"
          "past_due"
        when "SUBSCRIPTION_STATE_CANCELED"
          "cancelled"
        when "SUBSCRIPTION_STATE_EXPIRED"
          "expired"
        else
          "pending"
        end
      end

      def active_renewal_state?(value)
        %w[SUBSCRIPTION_STATE_ACTIVE SUBSCRIPTION_STATE_IN_GRACE_PERIOD].include?(value.to_s)
      end

      def cancelled_state?(value)
        %w[SUBSCRIPTION_STATE_CANCELED SUBSCRIPTION_STATE_EXPIRED].include?(value.to_s)
      end

      def notification_type_name(value)
        NOTIFICATION_TYPES[value.to_i] || "unknown"
      end

      def decode_pubsub_notification(payload)
        message = payload["message"] || {}
        data = message["data"].to_s
        return payload if payload["subscriptionNotification"].present?
        return {} if data.blank?

        parse_json(Base64.decode64(data))
      end

      def bearer_token(request)
        auth = request.headers["Authorization"].to_s
        auth = request.headers["authorization"].to_s if auth.blank?
        auth[/\ABearer\s+(.+)\z/i, 1]
      end

      def verify_pubsub_oidc_token!(token)
        header = JWT.decode(token, nil, false).last
        kid = header["kid"].to_s
        key = pubsub_public_keys[kid]
        raise "Unknown Google OIDC key id" if key.blank?

        JWT.decode(
          token,
          key,
          true,
          algorithm: "RS256",
          iss: ["https://accounts.google.com", "accounts.google.com"],
          verify_iss: true,
          aud: pubsub_audience,
          verify_aud: pubsub_audience.present?
        )
      end

      def pubsub_audience
        SiteSetting.google_play_pubsub_audience.to_s.presence
      end

      def pubsub_public_keys
        Rails.cache.fetch("google_play_pubsub_oidc_keys", expires_in: 1.hour) do
          url = URI.parse(PUBSUB_CERTS_URI)
          resp = perform_http(url, Net::HTTP::Get.new(url.request_uri))
          body = parse_json(resp.body)
          Array(body["keys"]).each_with_object({}) do |jwk, acc|
            acc[jwk["kid"]] = JWT::JWK.import(jwk).public_key
          end
        end
      end

      def access_token
        Rails.cache.fetch("google_play_androidpublisher_access_token", expires_in: 50.minutes) do
          fetch_access_token
        end
      end

      def fetch_access_token
        account = service_account
        now = Time.now.to_i
        assertion = JWT.encode(
          {
            iss: account.fetch("client_email"),
            scope: ANDROID_PUBLISHER_SCOPE,
            aud: account.fetch("token_uri", TOKEN_URI),
            exp: now + 3600,
            iat: now
          },
          OpenSSL::PKey::RSA.new(account.fetch("private_key")),
          "RS256"
        )

        url = URI.parse(account.fetch("token_uri", TOKEN_URI))
        req = Net::HTTP::Post.new(url.request_uri)
        req["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion: assertion
        )

        resp = perform_http(url, req)
        unless resp.code.to_i.between?(200, 299)
          raise "Google OAuth token error HTTP #{resp.code}: #{resp.body}"
        end

        parse_json(resp.body).fetch("access_token")
      end

      def service_account
        raw = SiteSetting.google_play_service_account_json.to_s
        raise "Google Play service account JSON is missing" if raw.blank?

        parse_json(raw).tap do |json|
          raise "Google Play service account JSON is invalid" unless json["client_email"].present? && json["private_key"].present?
        end
      end

      def perform_http(url, request)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = url.scheme == "https"
        http.open_timeout = 10
        http.read_timeout = 30
        http.request(request)
      end

      def parse_json(value)
        JSON.parse(value.to_s)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
