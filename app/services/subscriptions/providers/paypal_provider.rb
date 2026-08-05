# frozen_string_literal: true

module Subscriptions
  module Providers
    class PaypalProvider < BaseProvider
      API_BASE_URL = "https://api-m.paypal.com"

      def provider_key
        "paypal"
      end

      def verify_webhook!(request)
        webhook_secret = SiteSetting.paypal_webhook_id.to_s
        return true if webhook_secret.blank?

        auth_algo = request.headers["PAYPAL-AUTH-ALGO"]
        cert_url = request.headers["PAYPAL-CERT-URL"]
        transmission_id = request.headers["PAYPAL-TRANSMISSION-ID"]
        transmission_sig = request.headers["PAYPAL-TRANSMISSION-SIG"]
        transmission_time = request.headers["PAYPAL-TRANSMISSION-TIME"]

        return false if [auth_algo, cert_url, transmission_id, transmission_sig, transmission_time].any?(&:blank?)

        payload = {
          auth_algo: auth_algo,
          cert_url: cert_url,
          transmission_id: transmission_id,
          transmission_sig: transmission_sig,
          transmission_time: transmission_time,
          webhook_id: SiteSetting.paypal_webhook_id.to_s,
          webhook_event: parse_json(request.raw_post.to_s)
        }

        response = HTTParty.post(
          "#{API_BASE_URL}/v1/notifications/verify-webhook-signature",
          headers: auth_headers,
          body: payload.to_json
        )

        return false unless response.code.between?(200, 299)

        result = parse_json(response.body.to_s)
        result["verification_status"] == "SUCCESS"
      end

      def process_webhook!(request)
        payload = parse_json(request.raw_post.to_s)
        event_type = payload["resource_type"].to_s
        resource = payload["resource"] || {}
        subscription_id = resource["id"].to_s

        return if subscription_id.blank?

        subscription = Subscription.find_by(provider_key: provider_key, provider_subscription_id: subscription_id)

        if subscription.blank?
          Rails.logger.warn("PayPal webhook: no matching Subscription for subscription_id #{subscription_id}")
          return
        end

        remote = fetch_remote_subscription(subscription)
        return if remote.blank?

        Billing::RemoteSnapshot.apply!(subscription:, remote:)
      end

      def start_checkout(subscription:, return_url:)
        plan_id = selected_plan_id
        raise "PayPal plan id is missing" if plan_id.blank?

        offering = Billing::Offering.current

        payload = {
          plan_id: plan_id,
          subscriber: {
            name: { given_name: subscription.user.name.to_s.presence || "User" },
            email_address: subscription.user.email
          },
          application_context: {
            brand_name: "CinelarTV",
            locale: "en-US",
            shipping_preference: "NO_SHIPPING",
            user_action: "SUBSCRIBE_NOW",
            return_url: return_url.presence || default_return_url,
            cancel_url: default_return_url
          },
          custom_id: subscription.id.to_s
        }

        response = HTTParty.post(
          "#{API_BASE_URL}/v1/billing/subscriptions",
          headers: auth_headers,
          body: payload.to_json
        )

        raise_api_error!(response, action: "checkout create") unless response.code.between?(200, 299)

        parsed = parse_json(response.body.to_s)
        approval_url = parsed["links"]&.find { |l| l["rel"] == "approve" }&.dig("href")

        {
          redirect_url: approval_url,
          provider_subscription_id: parsed["id"],
          provider_customer_id: nil,
          provider_plan_id: plan_id
        }
      end

      def fetch_remote_subscription(subscription)
        return nil if subscription.provider_subscription_id.blank?

        response = HTTParty.get(
          "#{API_BASE_URL}/v1/billing/subscriptions/#{subscription.provider_subscription_id}",
          headers: auth_headers
        )

        if response.code == 404
          raise ActiveRecord::RecordNotFound, "PayPal subscription not found: #{subscription.provider_subscription_id}"
        end

        raise_api_error!(response, action: "subscription fetch") unless response.code.between?(200, 299)

        normalize_remote_subscription(parse_json(response.body.to_s))
      end

      def cancel(subscription)
        return unless subscription.provider_subscription_id.present?

        response = HTTParty.post(
          "#{API_BASE_URL}/v1/billing/subscriptions/#{subscription.provider_subscription_id}/cancel",
          headers: auth_headers,
          body: { reason: "Subscription cancelled by user" }.to_json
        )

        raise_api_error!(response, action: "subscription cancel") unless response.code.between?(200, 299)
      end

      def list_plans!
        { "results" => [] }
      end

      def create_plan!(_params)
        raise "PayPal plans must be managed in PayPal Dashboard"
      end

      def update_plan!(_plan_id, _params)
        raise "PayPal plans must be managed in PayPal Dashboard"
      end

      def deactivate_plan!(_plan_id)
        raise "PayPal plans must be managed in PayPal Dashboard"
      end

      def provider_metadata
        {
          provider_name: provider_key,
          provider_logo: nil,
          supported_regions: [],
          checkout_type: "redirect"
        }
      end

      private

      def normalize_remote_subscription(parsed)
        status = normalize_paypal_status(parsed["status"])
        next_billing_time = parsed.dig("billing_info", "next_billing_time")
        last_payment = parsed.dig("billing_info", "last_payment") || {}

        {
          "id" => parsed["id"],
          "status" => status,
          "renews_at" => next_billing_time,
          "ends_at" => parsed["status"] == "CANCELLED" ? (next_billing_time || Time.current.iso8601) : nil,
          "auto_recurring" => {
            "next_payment_date" => next_billing_time,
            "end_date" => parsed["status"] == "CANCELLED" ? next_billing_time : nil
          },
          "current_period_start" => parsed["start_time"],
          "updated_at" => parsed["update_time"],
          "last_payment" => {
            "amount" => last_payment["amount"],
            "currency" => last_payment["currency_code"],
            "date" => last_payment["time"]
          }
        }
      end

      def normalize_paypal_status(status)
        case status.to_s.upcase
        when "ACTIVE" then "active"
        when "APPROVED" then "pending"
        when "CANCELLED" then "cancelled"
        when "EXPIRED" then "expired"
        when "SUSPENDED" then "past_due"
        when "PENDING" then "pending"
        else "pending"
        end
      end

      def auth_headers
        token = fetch_access_token
        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      end

      def fetch_access_token
        client_id = SiteSetting.paypal_client_id.to_s.strip
        client_secret = SiteSetting.paypal_client_secret.to_s.strip

        raise "PayPal client_id is missing" if client_id.blank?
        raise "PayPal client_secret is missing" if client_secret.blank?

        response = HTTParty.post(
          "#{API_BASE_URL}/v1/oauth2/token",
          headers: {
            "Accept" => "application/json",
            "Accept-Language" => "en_US",
            "Content-Type" => "application/x-www-form-urlencoded"
          },
          body: {
            grant_type: "client_credentials"
          },
          basic_auth: { username: client_id, password: client_secret }
        )

        raise_api_error!(response, action: "access token") unless response.code.between?(200, 299)

        parsed = parse_json(response.body.to_s)
        parsed["access_token"]
      end

      def selected_plan_id
        SiteSetting.paypal_plan_id.to_s.strip.presence
      end

      def parse_json(value)
        JSON.parse(value.to_s)
      rescue JSON::ParserError
        {}
      end

      def raise_api_error!(response, action:)
        body = response.body.to_s
        parsed = parse_json(body)
        name = parsed["name"].to_s
        message = parsed["message"].to_s

        Rails.logger.error("PayPal API error during #{action}: HTTP #{response.code}. Response body: #{body}")

        if response.code.to_i == 401
          raise "PayPal #{action} error (401 Unauthorized). " \
                "Verify SiteSetting.paypal_client_id and paypal_client_secret are valid. " \
                "Provider response: #{[name, message].reject(&:blank?).join(" - ").presence || body}"
        end

        detail = [name, message].reject(&:blank?).join(" - ").presence || body
        raise "PayPal #{action} error (#{response.code}): #{detail}"
      end

      def default_return_url
        url = SiteSetting.base_url.to_s.strip
        raise "SiteSetting.base_url is not configured. Set it in Admin → Settings → General." if url.blank? || url.start_with?("/")
        "#{url.chomp("/")}/account/billing"
      end
    end
  end
end
