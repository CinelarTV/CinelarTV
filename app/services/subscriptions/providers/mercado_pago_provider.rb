# frozen_string_literal: true

module Subscriptions
  module Providers
    class MercadoPagoProvider < BaseProvider
      API_BASE_URL = "https://api.mercadopago.com"

      def provider_key
        "mercado_pago"
      end

      def verify_webhook!(request)
        return true if SiteSetting.mercadopago_webhook_secret.blank?

        signature = request.headers["X-Provider-Signature"].to_s
        return false if signature.blank?

        local_signature = OpenSSL::HMAC.hexdigest("SHA256", SiteSetting.mercadopago_webhook_secret, request.raw_post.to_s)
        ActiveSupport::SecurityUtils.secure_compare(local_signature, signature)
      end

      def process_webhook!(request)
        payload = parse_payload(request)
        payment_id = extract_payment_id(request, payload)
        raise ArgumentError, "Missing payment id" if payment_id.blank?

        payment_data = fetch_payment(payment_id)
        upsert_subscription_from_payment!(payment_data)
      end

      def create_checkout!(user:, success_url: nil, failure_url: nil, pending_url: nil)
        response = HTTParty.post(
          "#{API_BASE_URL}/checkout/preferences",
          headers: auth_headers,
          body: checkout_payload(user, success_url:, failure_url:, pending_url:).to_json
        )

        raise "MercadoPago checkout error: #{response.body}" unless response.code.between?(200, 299)

        parsed = JSON.parse(response.body)
        {
          provider: provider_key,
          checkout_url: parsed["init_point"],
          sandbox_checkout_url: parsed["sandbox_init_point"],
          preference_id: parsed["id"]
        }
      end

      def fetch_subscription!(subscription)
        return nil if subscription.provider_subscription_id.blank?

        fetch_payment(subscription.provider_subscription_id)
      end

      def cancel_subscription!(subscription)
        subscription.update!(
          status: "cancelled",
          external_status: "cancelled_by_admin",
          cancelled: true,
          cancelled_at: Time.zone.now
        )
      end

      private

      def parse_payload(request)
        JSON.parse(request.raw_post.to_s)
      rescue JSON::ParserError
        {}
      end

      def extract_payment_id(request, payload)
        params = request.query_parameters

        params["data.id"] ||
          payload.dig("data", "id") ||
          payload["id"] ||
          params["id"]
      end

      def fetch_payment(payment_id)
        response = HTTParty.get("#{API_BASE_URL}/v1/payments/#{payment_id}", headers: auth_headers)
        raise "MercadoPago payment fetch error: #{response.body}" unless response.code.between?(200, 299)

        JSON.parse(response.body)
      end

      def upsert_subscription_from_payment!(payment)
        external_reference = payment["external_reference"].to_s
        metadata = payment["metadata"] || {}

        user = find_user_for_payment(external_reference, metadata, payment)
        raise ActiveRecord::RecordNotFound, "User not found for MercadoPago payment #{payment["id"]}" if user.nil?

        subscription = UserSubscription.find_or_initialize_by(user_id: user.id)
        status = normalize_status(payment["status"])

        subscription.update!(
          provider: provider_key,
          provider_subscription_id: payment["id"].to_s,
          provider_customer_id: payment.dig("payer", "id")&.to_s,
          provider_plan_id: SiteSetting.mercadopago_plan_id.presence,
          checkout_reference: external_reference.presence,
          status: status,
          status_formatted: status.humanize,
          external_status: payment["status"].to_s,
          product_name: SiteSetting.mercadopago_plan_title.presence || "Subscription",
          variant_name: SiteSetting.mercadopago_plan_interval.presence || "monthly",
          user_name: payment.dig("payer", "first_name") || user.username,
          user_email: payment.dig("payer", "email") || user.email,
          cancelled: status == "cancelled",
          cancelled_at: status == "cancelled" ? Time.zone.now : nil,
          renews_at: subscription_cycle_end,
          ends_at: status == "cancelled" ? Time.zone.now : nil,
          metadata: payment
        )

        subscription
      end

      def find_user_for_payment(external_reference, metadata, payment)
        user_id = external_reference.presence || metadata["user_id"]
        return User.find_by(id: user_id) if user_id.present?

        email = payment.dig("payer", "email")
        return nil if email.blank?

        User.find_by(email: email)
      end

      def subscription_cycle_end
        interval = SiteSetting.mercadopago_plan_interval.presence || "monthly"

        case interval
        when "yearly"
          1.year.from_now
        else
          1.month.from_now
        end
      end

      def checkout_payload(user, success_url:, failure_url:, pending_url:)
        {
          items: [
            {
              title: SiteSetting.mercadopago_plan_title.presence || "CinelarTV Subscription",
              quantity: 1,
              currency_id: SiteSetting.mercadopago_plan_currency.presence || "USD",
              unit_price: SiteSetting.mercadopago_plan_price.to_f
            }
          ],
          external_reference: user.id,
          payer: {
            email: user.email
          },
          back_urls: {
            success: success_url.presence || SiteSetting.mercadopago_success_url.presence || default_return_url,
            failure: failure_url.presence || SiteSetting.mercadopago_failure_url.presence || default_return_url,
            pending: pending_url.presence || SiteSetting.mercadopago_pending_url.presence || default_return_url
          },
          auto_return: "approved",
          notification_url: webhook_url,
          statement_descriptor: "CINELARTV"
        }
      end

      def auth_headers
        token = SiteSetting.mercadopago_access_token.to_s
        raise "MercadoPago access token is missing" if token.blank?

        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end

      def default_return_url
        "#{SiteSetting.base_url}/account/billing"
      end

      def webhook_url
        "#{SiteSetting.base_url}/subscriptions/webhooks/#{provider_key}"
      end
    end
  end
end
