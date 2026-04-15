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

        signature_header = request.headers["X-Signature"].to_s
        signature_header = request.headers["x-signature"].to_s if signature_header.blank?
        signature_header = request.headers["X-Provider-Signature"].to_s if signature_header.blank?
        return false if signature_header.blank?

        signature_parts = parse_signature_header(signature_header)
        
        if signature_parts[:v1].present? && signature_parts[:ts].present?
          request_id = request.headers["X-Request-Id"].to_s
          request_id = request.headers["x-request-id"].to_s if request_id.blank?
          data_id = request.query_parameters["data.id"].presence || 
                    request.query_parameters["id"].presence ||
                    parse_payload(request).dig("data", "id")

          manifest = webhook_manifest(data_id: data_id, request_id: request_id, ts: signature_parts[:ts])
          local_signature = OpenSSL::HMAC.hexdigest("SHA256", SiteSetting.mercadopago_webhook_secret, manifest)
          return secure_compare_hex(local_signature, signature_parts[:v1])
        end

        # Backward compatibility: some integrations send only the raw HMAC signature.
        local_signature = OpenSSL::HMAC.hexdigest("SHA256", SiteSetting.mercadopago_webhook_secret, request.raw_post.to_s)
        secure_compare_hex(local_signature, signature_header)
      end

      def process_webhook!(request)
        payload = parse_payload(request)
        resource_id = extract_resource_id(request, payload)
        event_type = extract_event_type(request, payload)
        
        raise ArgumentError, "Missing resource id" if resource_id.blank?

        case event_type
        when "preapproval"
          preapproval_data = fetch_preapproval(resource_id)
          upsert_subscription_from_preapproval!(preapproval_data)
        when "payment", "merchant_order"
          # Payment events are handled separately or logged for reference
          Rails.logger.info("MercadoPago #{event_type} event received: #{resource_id}")
        else
          Rails.logger.warn("Unknown MercadoPago event type: #{event_type}")
          upsert_subscription_from_preapproval!(fetch_preapproval(resource_id))
        end
      end

      def create_subscription!(user:, success_url: nil, failure_url: nil, pending_url: nil, card_token_id: nil,
        start_date: nil, end_date: nil, amount: nil, currency_id: nil, frequency: nil, frequency_type: nil,
        repetitions: nil, billing_day: nil, billing_day_proportional: nil)
        plan_id = SiteSetting.mercadopago_plan_id.to_s

        if plan_id.present? && card_token_id.blank?
          return {
            provider: provider_key,
            checkout_url: plan_checkout_url(
              plan_id: plan_id,
              user: user,
              success_url: success_url
            ),
            preapproval_id: nil,
            plan_id: plan_id,
            webhook_note: "Webhook notifications require app-level configuration in MercadoPago dashboard"
          }
        end

        payload = if plan_id.present?
                    preapproval_payload_with_plan(
                      user,
                      plan_id:,
                      success_url:,
                      failure_url:,
                      pending_url:,
                      card_token_id:,
                      start_date:,
                      end_date:,
                      amount:,
                      currency_id:,
                      frequency:,
                      frequency_type:,
                      repetitions:,
                      billing_day:,
                      billing_day_proportional:
                    )
                  else
                    preapproval_payload_without_plan(
                      user,
                      success_url:,
                      failure_url:,
                      pending_url:,
                      start_date:,
                      end_date:,
                      amount:,
                      currency_id:,
                      frequency:,
                      frequency_type:,
                      repetitions:,
                      billing_day:,
                      billing_day_proportional:
                    )
                  end

        response = HTTParty.post("#{API_BASE_URL}/preapproval", headers: auth_headers, body: payload.to_json)

        raise "MercadoPago preapproval error: #{response.body}" unless response.code.between?(200, 299)

        parsed = JSON.parse(response.body)
        {
          provider: provider_key,
          checkout_url: parsed["init_point"],
          preapproval_id: parsed["id"],
          plan_id: parsed["preapproval_plan_id"]
        }
      end

      alias create_checkout! create_subscription!

      def fetch_subscription!(subscription)
        return nil if subscription.provider_subscription_id.blank?

        fetch_preapproval(subscription.provider_subscription_id)
      end

      def cancel_subscription!(subscription)
        if subscription.provider_subscription_id.present?
          response = HTTParty.put(
            "#{API_BASE_URL}/preapproval/#{subscription.provider_subscription_id}",
            headers: auth_headers,
            body: { status: "cancelled" }.to_json
          )

          raise "MercadoPago cancel error: #{response.body}" unless response.code.between?(200, 299)
        end

        subscription.update!(
          status: "cancelled",
          external_status: "cancelled_by_admin",
          cancelled: true,
          cancelled_at: Time.zone.now
        )
      end

      def list_plans!(managed_only: true)
        response = HTTParty.get("#{API_BASE_URL}/preapproval_plan/search?limit=100", headers: auth_headers)
        raise "MercadoPago plans fetch error: #{response.body}" unless response.code.between?(200, 299)

        parsed = JSON.parse(response.body)
        return parsed unless managed_only

        # When managed_only is true, only show plans that belong to this CinelarTV instance
        plans = parsed["results"] || []
        parsed["results"] = plans.select { |plan| cinelar_plan?(plan) }
        parsed
      end

      def create_plan!(params)
        reason = params[:reason].presence || "CinelarTV Subscription"
        reason = "[CinelarTV] #{reason}" unless reason.to_s.include?("[CinelarTV]")

        body = {
          reason: reason,
          auto_recurring: {
            frequency: params[:frequency].presence&.to_i || default_frequency,
            frequency_type: params[:frequency_type].presence || default_frequency_type,
            transaction_amount: params[:amount].presence&.to_f || 9.99,
            currency_id: params[:currency_id].presence || "UYU"
          },
          back_url: params[:back_url].presence || default_return_url,
          status: params[:status].presence || "active"
        }

        response = HTTParty.post("#{API_BASE_URL}/preapproval_plan", headers: auth_headers, body: body.to_json)
        raise "MercadoPago create plan error: #{response.body}" unless response.code.between?(200, 299)

        JSON.parse(response.body)
      end

      def update_plan!(plan_id, params)
        body = {
          reason: params[:reason],
          auto_recurring: {
            frequency: params[:frequency]&.to_i,
            frequency_type: params[:frequency_type],
            transaction_amount: params[:amount]&.to_f,
            currency_id: params[:currency_id]
          }.compact,
          back_url: params[:back_url],
          status: params[:status]
        }.compact

        response = HTTParty.put("#{API_BASE_URL}/preapproval_plan/#{plan_id}", headers: auth_headers, body: body.to_json)
        raise "MercadoPago update plan error: #{response.body}" unless response.code.between?(200, 299)

        JSON.parse(response.body)
      end

      def deactivate_plan!(plan_id)
        update_plan!(plan_id, status: "cancelled")
      end

      private

      def parse_payload(request)
        return @parsed_payload if defined?(@parsed_payload)
        
        raw = request.raw_post.to_s
        @parsed_payload = raw.present? ? JSON.parse(raw) : {}
      rescue JSON::ParserError
        @parsed_payload = {}
      end

      def extract_event_type(request, payload)
        # Try to extract from X-Topic header first
        topic = request.headers["X-Topic"].to_s
        return topic.downcase if topic.present?

        # Then try payload fields
        payload.dig("data", "type") ||
          payload["type"] ||
          request.query_parameters["type"] ||
          "preapproval"
      end

      def parse_signature_header(value)
        value.to_s.split(",").map(&:strip).each_with_object({}) do |part, acc|
          key, val = part.split("=", 2)
          next if key.blank? || val.blank?

          acc[key.to_sym] = val
        end
      end

      def webhook_manifest(data_id:, request_id:, ts:)
        "id:#{data_id};request-id:#{request_id};ts:#{ts};"
      end

      def secure_compare_hex(a, b)
        a_s = a.to_s.downcase
        b_s = b.to_s.downcase
        return false if a_s.blank? || b_s.blank? || a_s.bytesize != b_s.bytesize

        ActiveSupport::SecurityUtils.secure_compare(a_s, b_s)
      end

      def extract_resource_id(request, payload)
        params = request.query_parameters

        params["data.id"] ||
          payload.dig("data", "id") ||
          payload["id"] ||
          params["id"]
      end

      def fetch_preapproval(preapproval_id)
        response = HTTParty.get("#{API_BASE_URL}/preapproval/#{preapproval_id}", headers: auth_headers)
        unless response.code.between?(200, 299)
          body = response.body.to_s
          # Mercado Pago webhook test tool often sends placeholder IDs (for example 123456).
          if response.code == 404 || (response.code == 400 && body.include?("Subscription bad request"))
            raise ActiveRecord::RecordNotFound, "Preapproval not found for webhook id #{preapproval_id}"
          end

          raise "MercadoPago preapproval fetch error: #{body}"
        end

        JSON.parse(response.body)
      end

      def upsert_subscription_from_preapproval!(preapproval)
        external_reference = preapproval["external_reference"].to_s
        metadata = preapproval["metadata"] || {}

        user = find_user_for_preapproval(external_reference, metadata, preapproval)
        raise ActiveRecord::RecordNotFound, "User not found for MercadoPago preapproval #{preapproval["id"]}" if user.nil?

        subscription = UserSubscription.find_or_initialize_by(user_id: user.id)
        raw_status = preapproval["status"].to_s
        status = normalize_status(raw_status)

        subscription.update!(
          provider: provider_key,
          provider_subscription_id: preapproval["id"].to_s,
          provider_customer_id: preapproval.dig("payer_id")&.to_s || preapproval.dig("payer", "id")&.to_s,
          provider_plan_id: preapproval["preapproval_plan_id"].presence || SiteSetting.mercadopago_plan_id.presence,
          checkout_reference: external_reference.presence,
          status: status,
          status_formatted: status.humanize,
          external_status: raw_status,
          product_name: preapproval["reason"].presence || "Subscription",
          variant_name: interval_from_preapproval(preapproval),
          user_name: user.username,
          user_email: preapproval.dig("payer_email").presence || preapproval.dig("payer", "email").presence || user.email,
          cancelled: %w[cancelled].include?(raw_status),
          cancelled_at: %w[cancelled].include?(raw_status) ? Time.zone.now : nil,
          renews_at: parse_time(preapproval.dig("auto_recurring", "next_payment_date")) || 1.month.from_now,
          ends_at: parse_time(preapproval.dig("auto_recurring", "end_date")),
          metadata: metadata.merge(preapproval.slice("status", "status_detail", "summarized", "operation_type"))
        )

        subscription
      end

      def find_user_for_preapproval(external_reference, metadata, preapproval)
        user_id = external_reference.presence || metadata["user_id"]
        return User.find_by(id: user_id) if user_id.present?

        email = preapproval["payer_email"]
        return nil if email.blank?

        User.find_by(email: email)
      end

      def preapproval_payload_with_plan(user, plan_id:, success_url:, failure_url:, pending_url:, card_token_id:,
        start_date:, end_date:, amount:, currency_id:, frequency:, frequency_type:, repetitions:, billing_day:,
        billing_day_proportional:)
        raise "card_token_id is required for plan-associated subscriptions" if card_token_id.blank?

        {
          preapproval_plan_id: plan_id,
          reason: "CinelarTV Subscription",
          external_reference: user.id,
          payer_email: user.email,
          card_token_id: card_token_id,
          back_url: success_url.presence || default_return_url,
          status: "authorized",
          notification_url: webhook_url,
          auto_recurring: {
            frequency: frequency.presence&.to_i || default_frequency,
            frequency_type: frequency_type.presence || default_frequency_type,
            start_date: normalize_iso_datetime(start_date),
            end_date: normalize_iso_datetime(end_date),
            transaction_amount: amount.presence&.to_f || 9.99,
            currency_id: currency_id.presence || "UYU",
            repetitions: repetitions.presence&.to_i,
            billing_day: billing_day.presence&.to_i,
            billing_day_proportional: cast_boolean(billing_day_proportional)
          }.compact,
          metadata: {
            user_id: user.id,
            site_id: SiteSetting.mercadopago_site_id.presence || "MLU",
            failure_url: failure_url,
            pending_url: pending_url
          }.compact
        }
      end

      def preapproval_payload_without_plan(user, success_url:, failure_url:, pending_url:, start_date:, end_date:, amount:,
        currency_id:, frequency:, frequency_type:, repetitions:, billing_day:, billing_day_proportional:)
        {
          reason: "CinelarTV Subscription",
          external_reference: user.id,
          payer_email: user.email,
          back_url: success_url.presence || default_return_url,
          status: "pending",
          notification_url: webhook_url,
          auto_recurring: {
            frequency: frequency.presence&.to_i || default_frequency,
            frequency_type: frequency_type.presence || default_frequency_type,
            start_date: normalize_iso_datetime(start_date),
            end_date: normalize_iso_datetime(end_date),
            transaction_amount: amount.presence&.to_f || 9.99,
            currency_id: currency_id.presence || "UYU",
            repetitions: repetitions.presence&.to_i,
            billing_day: billing_day.presence&.to_i,
            billing_day_proportional: cast_boolean(billing_day_proportional)
          },
          metadata: {
            user_id: user.id,
            site_id: SiteSetting.mercadopago_site_id.presence || "MLU",
            failure_url: failure_url,
            pending_url: pending_url
          }.compact
        }
      end

      def default_frequency_type
        "months"
      end

      def default_frequency
        1
      end

      def interval_from_preapproval(preapproval)
        frequency = preapproval.dig("auto_recurring", "frequency").to_i
        frequency_type = preapproval.dig("auto_recurring", "frequency_type").to_s
        return "yearly" if frequency_type == "months" && frequency == 12

        "monthly"
      end

      def normalize_iso_datetime(value)
        return nil if value.blank?

        Time.zone.parse(value.to_s).utc.iso8601
      rescue ArgumentError, TypeError
        nil
      end

      def cast_boolean(value)
        return nil if value.nil?

        ActiveModel::Type::Boolean.new.cast(value)
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

      def cinelar_plan?(plan)
        # If this plan is the one selected in settings, always show it
        return true if plan["id"].to_s == SiteSetting.mercadopago_plan_id.to_s

        # Check if the plan was created by CinelarTV (has our marker in reason or back_url)
        reason = plan["reason"].to_s
        back_url = plan["back_url"].to_s
        base_url = SiteSetting.base_url.to_s

        reason.include?("CinelarTV") || (base_url.present? && back_url.include?(base_url))
      end

      def plan_checkout_url(plan_id:, user:, success_url:)
        base = "https://www.#{mercadopago_host}/subscriptions/checkout"
        params = {
          preapproval_plan_id: plan_id,
          external_reference: user.id,
          payer_email: user.email,
          back_url: success_url.presence || default_return_url,
          # Note: notification_url cannot be passed via checkout URL parameters
          # It must be configured in the MercadoPago application settings or plan
        }.compact

        "#{base}?#{URI.encode_www_form(params)}"
      end

      def mercadopago_host
        site_id = SiteSetting.mercadopago_site_id.to_s.upcase

        case site_id
        when "MLA"
          "mercadopago.com.ar"
        when "MLB"
          "mercadopago.com.br"
        when "MLC"
          "mercadopago.cl"
        when "MLM"
          "mercadopago.com.mx"
        when "MPE"
          "mercadopago.com.pe"
        when "MCO"
          "mercadopago.com.co"
        else
          "mercadopago.com.uy"
        end
      end
    end
  end
end
