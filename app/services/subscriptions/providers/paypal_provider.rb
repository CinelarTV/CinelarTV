# frozen_string_literal: true

module Subscriptions
  module Providers
    class PaypalProvider < BaseProvider
      def provider_key
        "paypal"
      end

      def api_base_url
        if SiteSetting.paypal_sandbox_mode
          "https://api-m.sandbox.paypal.com"
        else
          "https://api-m.paypal.com"
        end
      end

      def management_url
        if SiteSetting.paypal_sandbox_mode
          "https://www.sandbox.paypal.com/myaccount/autopay/"
        else
          "https://www.paypal.com/myaccount/autopay/"
        end
      end

      def verify_webhook!(request)
        webhook_secret = SiteSetting.paypal_webhook_id.to_s
        return true if webhook_secret.blank?

        auth_algo = request.headers["PAYPAL-AUTH-ALGO"] || request.headers["paypal-auth-algo"]
        cert_url = request.headers["PAYPAL-CERT-URL"] || request.headers["paypal-cert-url"]
        transmission_id = request.headers["PAYPAL-TRANSMISSION-ID"] || request.headers["paypal-transmission-id"]
        transmission_sig = request.headers["PAYPAL-TRANSMISSION-SIG"] || request.headers["paypal-transmission-sig"]
        transmission_time = request.headers["PAYPAL-TRANSMISSION-TIME"] || request.headers["paypal-transmission-time"]

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
          "#{api_base_url}/v1/notifications/verify-webhook-signature",
          headers: auth_headers,
          body: payload.to_json
        )

        return false unless response.code.between?(200, 299)

        result = parse_json(response.body.to_s)
        result["verification_status"] == "SUCCESS"
      end

      def process_webhook!(request)
        payload = parse_json(request.raw_post.to_s)
        event_type = payload["event_type"].to_s
        resource = payload["resource"] || {}
        resource_type = payload["resource_type"].to_s

        subscription_id = resource["billing_agreement_id"].presence || resource["id"].to_s
        return if subscription_id.blank?

        if event_type == "PAYMENT.SALE.COMPLETED" || resource_type.downcase == "sale"
          record_sale_payment!(resource, subscription_id)
        end

        subscription = Subscription.find_by(provider_key: provider_key, provider_subscription_id: subscription_id)

        if subscription.blank?
          custom_id = resource["custom_id"].to_s.presence || resource["custom"].to_s.presence
          subscription = Subscription.find_by(id: custom_id) if custom_id.present?
          if subscription && subscription.provider_subscription_id.blank?
            subscription.update!(provider_subscription_id: subscription_id)
          end
        end

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
            name: { given_name: subscription.user.username.presence || subscription.user.email.split("@").first.presence || "User" },
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
          "#{api_base_url}/v1/billing/subscriptions",
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
          "#{api_base_url}/v1/billing/subscriptions/#{subscription.provider_subscription_id}",
          headers: auth_headers
        )

        if response.code == 404
          raise ActiveRecord::RecordNotFound, "PayPal subscription not found: #{subscription.provider_subscription_id}"
        end

        raise_api_error!(response, action: "subscription fetch") unless response.code.between?(200, 299)

        normalize_remote_subscription(parse_json(response.body.to_s))
      end

      def fetch_payment(payment_id)
        return nil if payment_id.blank?

        response = HTTParty.get(
          "#{api_base_url}/v1/payments/sale/#{payment_id}",
          headers: auth_headers
        )

        return nil if response.code == 404
        raise_api_error!(response, action: "sale payment fetch") unless response.code.between?(200, 299)

        parsed = parse_json(response.body.to_s)
        amount_val = parsed.dig("amount", "total") || parsed.dig("amount", "value")
        currency = parsed.dig("amount", "currency") || parsed.dig("amount", "currency_code")

        {
          "id" => parsed["id"],
          "subscription_id" => parsed["billing_agreement_id"],
          "billing_agreement_id" => parsed["billing_agreement_id"],
          "status" => parsed["state"] || parsed["status"],
          "transaction_amount" => amount_val,
          "currency_id" => currency,
          "currency" => currency,
          "date_created" => parsed["create_time"],
          "date_approved" => parsed["update_time"] || parsed["create_time"],
          "status_detail" => parsed["reason_code"] || parsed["state"],
          "operation_type" => "recurring_payment",
          "payment_method_id" => parsed["payment_mode"] || "paypal"
        }
      end

      def cancel(subscription)
        return unless subscription.provider_subscription_id.present?

        response = HTTParty.post(
          "#{api_base_url}/v1/billing/subscriptions/#{subscription.provider_subscription_id}/cancel",
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
          checkout_type: "redirect",
          management_url: management_url
        }
      end

      private

      def record_sale_payment!(resource, subscription_id)
        sale_id = resource["id"].to_s
        return if sale_id.blank?

        subscription = Subscription.find_by(provider_key: provider_key, provider_subscription_id: subscription_id)
        if subscription.blank?
          custom_id = resource["custom_id"].to_s.presence || resource["custom"].to_s.presence
          subscription = Subscription.find_by(id: custom_id) if custom_id.present?
        end
        return if subscription.blank?

        status = case resource["state"].to_s.downcase
                 when "completed" then "succeeded"
                 when "refunded", "partially_refunded" then "refunded"
                 when "denied", "failed" then "failed"
                 else "pending"
                 end

        amount_val = resource.dig("amount", "total") || resource.dig("amount", "value")
        currency = resource.dig("amount", "currency") || resource.dig("amount", "currency_code") || subscription.currency
        amount_cents = (BigDecimal(amount_val.to_s) * 100).round.to_i rescue subscription.amount_cents

        payment = Payment.find_or_initialize_by(
          provider_key: provider_key,
          provider_payment_id: sale_id
        )
        payment.assign_attributes(
          subscription: subscription,
          user: subscription.user,
          kind: payment.persisted? ? payment.kind : "renewal",
          status: status,
          amount_cents: amount_cents,
          currency: currency,
          attempted_at: parse_time(resource["create_time"]),
          paid_at: parse_time(resource["update_time"] || resource["create_time"]),
          failure_code: resource["reason_code"],
          provider_metadata: resource.slice("payment_mode", "state", "protection_eligibility")
        )
        payment.save!
      rescue StandardError => e
        Rails.logger.error("PayPal error recording payment #{sale_id}: #{e.class} - #{e.message}")
      end

      def normalize_remote_subscription(parsed)
        status = normalize_paypal_status(parsed["status"])
        next_billing_time = parsed.dig("billing_info", "next_billing_time")
        last_payment = parsed.dig("billing_info", "last_payment") || {}

        last_amount = last_payment.is_a?(Hash) ? (last_payment.dig("amount", "value") || last_payment["amount"]) : nil
        last_currency = last_payment.is_a?(Hash) ? (last_payment.dig("amount", "currency_code") || last_payment["currency_code"] || last_payment["currency"]) : nil

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
            "amount" => last_amount,
            "currency" => last_currency,
            "date" => last_payment.is_a?(Hash) ? last_payment["time"] : nil
          },
          "management_url" => management_url
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

        cache_key = "paypal_access_token_#{Digest::SHA256.hexdigest("#{client_id}:#{SiteSetting.paypal_sandbox_mode}")}"
        cached = Rails.cache.read(cache_key)
        return cached if cached.present?

        response = HTTParty.post(
          "#{api_base_url}/v1/oauth2/token",
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
        token = parsed["access_token"]
        expires_in = (parsed["expires_in"] || 32400).to_i - 300
        Rails.cache.write(cache_key, token, expires_in: [expires_in, 3600].max.seconds)
        token
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
          client_id = SiteSetting.paypal_client_id.to_s.strip
          Rails.cache.delete("paypal_access_token_#{Digest::SHA256.hexdigest("#{client_id}:#{SiteSetting.paypal_sandbox_mode}")}")
          raise "PayPal #{action} error (401 Unauthorized). "                 "Verify SiteSetting.paypal_client_id and paypal_client_secret are valid. "                 "Provider response: #{[name, message].reject(&:blank?).join(" - ").presence || body}"
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
