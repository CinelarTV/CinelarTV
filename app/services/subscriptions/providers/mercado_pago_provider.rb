# frozen_string_literal: true

module Subscriptions
  module Providers
    class MercadoPagoProvider < BaseProvider
      API_BASE_URL = "https://api.mercadopago.com"

      # Optional site_id override. When nil, uses the first enabled account.
      # Set by calling MercadoPagoProvider.new(site_id: "MLU")
      attr_reader :site_id

      def initialize(site_id: nil)
        @site_id = site_id.to_s.upcase.presence
      end

      def provider_key
        "mercado_pago"
      end

      def verify_webhook!(request)
        secret = current_account_webhook_secret(request)
        return true if secret.blank?

        signature_header = request.headers["X-Signature"].to_s
        signature_header = request.headers["x-signature"].to_s if signature_header.blank?
        signature_header = request.headers["X-Provider-Signature"].to_s if signature_header.blank?
        return false if signature_header.blank?

        signature_parts = parse_signature_header(signature_header)
        return false if signature_parts[:v1].blank? || signature_parts[:ts].blank?

        request_id = request.headers["X-Request-Id"].to_s
        request_id = request.headers["x-request-id"].to_s if request_id.blank?
        data_id = request.query_parameters["data.id"].presence ||
                  request.query_parameters["id"].presence ||
                  parse_payload(request).dig("data", "id")

        manifest = webhook_manifest(data_id: data_id, request_id: request_id, ts: signature_parts[:ts])
        local_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)
        secure_compare_hex(local_signature, signature_parts[:v1])
      end

      def process_webhook!(request)
        payload = parse_payload(request)
        resource_id = extract_resource_id(request, payload)
        event_type = extract_event_type(request, payload)
        webhook_application_id = extract_application_id(request, payload)

        raise ArgumentError, "Missing resource id" if resource_id.blank?

        if configured_application_id.present? && webhook_application_id.present? && webhook_application_id.to_s != configured_application_id.to_s
          Rails.logger.warn(
            "MercadoPago webhook ignored due to application_id mismatch: received=#{webhook_application_id} " \
            "expected=#{configured_application_id} event_type=#{event_type} resource_id=#{resource_id}"
          )
          return
        end

        case event_type
        when "preapproval", "subscription_preapproval"
          preapproval_data = fetch_preapproval(resource_id)
          preapproval_data = enrich_preapproval_from_search(preapproval_data, resource_id, webhook_application_id)
          upsert_subscription_from_preapproval!(preapproval_data)
        when "payment"
          process_payment_event!(resource_id)
        when "subscription_authorized_payment"
          Rails.logger.info("MercadoPago subscription_authorized_payment event received: #{resource_id} (ignoring in favor of standard payment event)")
        when "merchant_order"
          Rails.logger.info("MercadoPago merchant_order event received: #{resource_id} (informational only)")
        else
          Rails.logger.warn("Unknown MercadoPago event type: #{event_type}")
          upsert_subscription_from_preapproval!(fetch_preapproval(resource_id))
        end
      end

      def start_checkout(subscription:, return_url:)
        plan_id = account_value(:plan_id).to_s
        validate_credentials_consistency!

        offering = Billing::Offering.current
        # Use the per-account price if configured, falling back to the global Offering
        account = resolve_account
        amount = account ? (account["amount_cents"].to_i / 100.0) : offering.amount
        currency_id = account ? account["currency"].to_s : offering.currency

        payload = if plan_id.present?
                    preapproval_payload_with_plan(
                      subscription.user,
                      plan_id:,
                      success_url: return_url,
                      amount: amount,
                      currency_id: currency_id,
                      frequency: offering.interval_count,
                      frequency_type: "#{offering.interval_unit}s",
                      external_reference: subscription.id
                    )
                  else
                    preapproval_payload_without_plan(
                      subscription.user,
                      success_url: return_url,
                      amount: amount,
                      currency_id: currency_id,
                      frequency: offering.interval_count,
                      frequency_type: "#{offering.interval_unit}s",
                      external_reference: subscription.id
                    )
                  end

        response = HTTParty.post("#{API_BASE_URL}/preapproval", headers: auth_headers, body: payload.to_json)

        if requires_card_token_fallback?(response, plan_id: plan_id)
          return {
            redirect_url: plan_checkout_url(plan_id:, user: subscription.user, success_url: return_url),
            provider_subscription_id: nil,
            provider_customer_id: nil,
            provider_plan_id: plan_id
          }
        end

        raise_preapproval_error!(response) unless response.code.between?(200, 299)

        parsed = JSON.parse(response.body)

        Rails.logger.info(
          "MercadoPago preapproval created id=#{parsed["id"]} external_reference=#{payload[:external_reference]} " \
          "metadata_user_id=#{payload.dig(:metadata, :user_id)} plan_id=#{parsed["preapproval_plan_id"] || payload[:preapproval_plan_id]} " \
          "application_id=#{configured_application_id || "unknown"}"
        )

        {
          redirect_url: parsed["init_point"],
          provider_subscription_id: parsed["id"],
          provider_customer_id: nil,
          provider_plan_id: parsed["preapproval_plan_id"]
        }
      end

      def fetch_remote_subscription(subscription)
        return nil if subscription.provider_subscription_id.blank?

        fetch_preapproval(subscription.provider_subscription_id)
      end

      def cancel(subscription)
        return unless subscription.provider_subscription_id.present?

        response = HTTParty.put(
          "#{API_BASE_URL}/preapproval/#{subscription.provider_subscription_id}",
          headers: auth_headers,
          body: { status: "cancelled" }.to_json
        )

        raise "MercadoPago cancel error: #{response.body}" unless response.code.between?(200, 299)
      end

      def list_plans!(managed_only: true)
        query = { limit: 100 }
        application_id = configured_application_id
        query[:application_id] = application_id if application_id.present?

        response = HTTParty.get("#{API_BASE_URL}/preapproval_plan/search?#{URI.encode_www_form(query)}", headers: auth_headers)
        raise "MercadoPago plans fetch error: #{response.body}" unless response.code.between?(200, 299)

        parsed = JSON.parse(response.body)
        plans = parsed["results"] || []
        plans = filter_plans_by_application(plans, application_id)

        unless managed_only
          parsed["results"] = plans
          return parsed
        end

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
          back_url: resolve_back_url(params[:back_url]),
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
          back_url: resolve_back_url(params[:back_url]),
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
        topic = request.headers["X-Topic"].to_s
        return topic.downcase if topic.present?

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

      def extract_application_id(request, payload)
        params = request.query_parameters

        payload["application_id"] ||
          payload.dig("webhook", "application_id") ||
          params["application_id"]
      end

      def fetch_preapproval(preapproval_id)
        response = HTTParty.get("#{API_BASE_URL}/preapproval/#{preapproval_id}", headers: auth_headers)
        unless response.code.between?(200, 299)
          body = response.body.to_s
          if response.code == 404 || (response.code == 400 && body.include?("Subscription bad request"))
            raise ActiveRecord::RecordNotFound, "Preapproval not found for webhook id #{preapproval_id}"
          end

          raise "MercadoPago preapproval fetch error: #{body}"
        end

        JSON.parse(response.body)
      end

      def fetch_payment(payment_id)
        response = HTTParty.get("#{API_BASE_URL}/v1/payments/#{payment_id}", headers: auth_headers)
        unless response.code.between?(200, 299)
          body = response.body.to_s
          if response.code == 404
            raise ActiveRecord::RecordNotFound, "Payment not found for id #{payment_id}"
          end

          raise "MercadoPago payment fetch error: #{body}"
        end

        JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise "MercadoPago payment parse error for #{payment_id}: #{e.message}"
      end

      def process_payment_event!(payment_id)
        payment = fetch_payment(payment_id)
        return if payment.blank?

        preapproval_id = payment["preapproval_id"].to_s.presence
        payment_status = payment["status"].to_s.downcase

        Rails.logger.info(
          "MercadoPago payment event payment_id=#{payment_id} preapproval_id=#{preapproval_id.presence || 'none'} " \
          "status=#{payment_status}"
        )

        # Find subscription by preapproval_id in the new billing domain
        subscription = if preapproval_id.present?
                         Subscription.find_by(provider_key: provider_key, provider_subscription_id: preapproval_id)
                       end

        # Fallback: fetch preapproval and find via external_reference (subscription UUID)
        if subscription.blank? && preapproval_id.present?
          preapproval_data = fetch_preapproval(preapproval_id)
          external_ref = preapproval_data["external_reference"].to_s
          subscription = Subscription.find_by(id: external_ref) if external_ref.present?
        end

        if subscription.blank?
          Rails.logger.warn("MercadoPago payment #{payment_id}: no matching subscription found. Ignoring.")
          return
        end

        # Record payment in the new Payment model
        record_payment(subscription, payment, payment_status)
      end

      def record_payment(subscription, mp_payment, payment_status)
        status = case payment_status
                 when "approved" then "succeeded"
                 when "refunded", "charged_back" then "refunded"
                 when "rejected", "cancelled" then "failed"
                 else "pending"
                 end

        payment = Payment.find_or_initialize_by(
          provider_key: provider_key,
          provider_payment_id: mp_payment["id"].to_s
        )
        payment.assign_attributes(
          subscription:,
          user: subscription.user,
          kind: payment.persisted? ? payment.kind : "renewal",
          status:,
          amount_cents: (BigDecimal(mp_payment["transaction_amount"].to_s) * 100).round.to_i,
          currency: mp_payment["currency_id"].presence || subscription.currency,
          attempted_at: parse_time(mp_payment["date_created"]),
          paid_at: parse_time(mp_payment["date_approved"]),
          failure_code: mp_payment["status_detail"],
          provider_metadata: mp_payment.slice("operation_type", "payment_method_id", "status_detail")
        )
        payment.save!
      end

      def upsert_subscription_from_preapproval!(preapproval)
        external_reference = preapproval["external_reference"].to_s
        metadata = preapproval["metadata"] || {}

        Rails.logger.info(
          "MercadoPago preapproval sync id=#{preapproval["id"]} application_id=#{preapproval["application_id"] || "unknown"} " \
          "external_reference=#{external_reference.presence || "none"}"
        )

        # external_reference is the Subscription UUID in the new billing domain
        subscription = Subscription.find_by(id: external_reference)
        if subscription.blank?
          Rails.logger.warn("MercadoPago preapproval #{preapproval["id"]}: no matching Subscription for external_reference #{external_reference}")
          return
        end

        raw_status = preapproval["status"].to_s
        period_end = parse_time(preapproval.dig("auto_recurring", "next_payment_date"))

        SubscriptionTransition.apply!(
          subscription:,
          status: normalize_status(raw_status),
          period_end:,
          remote_updated_at: Time.current,
          metadata: {
            "remote_status" => raw_status,
            "mercadopago_preapproval_id" => preapproval["id"],
            "payer_email" => preapproval["payer_email"].presence || preapproval.dig("payer", "email")
          }
        )

        subscription
      end

      def search_preapproval(preapproval_id:, application_id: nil)
        query = { limit: 1, offset: 0, id: preapproval_id }
        query[:application_id] = application_id if application_id.present?

        response = HTTParty.get(
          "#{API_BASE_URL}/preapproval/search?#{URI.encode_www_form(query)}",
          headers: auth_headers
        )

        return nil unless response.code.between?(200, 299)

        parsed = JSON.parse(response.body)
        (parsed["results"] || []).first
      rescue StandardError => e
        Rails.logger.warn("MercadoPago preapproval search fallback failed for #{preapproval_id}: #{e.class} - #{e.message}")
        nil
      end

      def enrich_preapproval_from_search(preapproval, resource_id, application_id)
        return preapproval if preapproval.blank?

        external_reference = preapproval["external_reference"].to_s
        metadata_user_id = (preapproval["metadata"] || {})["user_id"].to_s
        payer_email = preapproval["payer_email"].presence || preapproval.dig("payer", "email").presence

        return preapproval if external_reference.present? || metadata_user_id.present? || payer_email.present?

        searched = search_preapproval(preapproval_id: resource_id, application_id: application_id)
        return preapproval if searched.blank?

        preapproval.merge(searched)
      end

      def preapproval_payload_with_plan(user, plan_id:, success_url:, amount:, currency_id:, frequency:, frequency_type:, external_reference: nil)
        {
          preapproval_plan_id: plan_id,
          reason: "CinelarTV Subscription",
          external_reference: external_reference.presence || user.id,
          payer_email: user.email,
          back_url: resolve_back_url(success_url),
          status: "pending",
          notification_url: webhook_url,
          auto_recurring: {
            frequency: frequency.presence&.to_i,
            frequency_type: frequency_type.presence,
            transaction_amount: amount.presence&.to_f,
            currency_id: currency_id.presence
          }.compact,
          metadata: {
            user_id: user.id,
            site_id: account_value(:site_id).presence || "MLU"
          }.compact
        }
      end

      def preapproval_payload_without_plan(user, success_url:, amount:, currency_id:, frequency:, frequency_type:, external_reference: nil)
        {
          reason: "CinelarTV Subscription",
          external_reference: external_reference.presence || user.id,
          payer_email: user.email,
          back_url: resolve_back_url(success_url),
          status: "pending",
          currency_id: currency_id.presence || "UYU",
          notification_url: webhook_url,
          auto_recurring: {
            frequency: frequency.presence&.to_i || default_frequency,
            frequency_type: frequency_type.presence || default_frequency_type,
            transaction_amount: amount.presence&.to_f || 9.99,
            currency_id: currency_id.presence || "UYU"
          },
          metadata: {
            user_id: user.id,
            site_id: account_value(:site_id).presence || "MLU"
          }.compact
        }
      end

      def default_frequency_type
        "months"
      end

      def default_frequency
        1
      end

      def requires_card_token_fallback?(response, plan_id:)
        return false if plan_id.blank?
        return false if response.code.between?(200, 299)

        body = response.body.to_s.downcase
        response.code == 400 && body.include?("card_token_id") && body.include?("required")
      end

      def raise_preapproval_error!(response)
        body = response.body.to_s
        parsed = JSON.parse(body)
        message = parsed["message"].to_s
        hint = preapproval_error_hint(message)

        if hint.present?
          raise "MercadoPago preapproval error: #{body} | #{hint}"
        end

        raise "MercadoPago preapproval error: #{body}"
      rescue JSON::ParserError
        raise "MercadoPago preapproval error: #{body}"
      end

      def preapproval_error_hint(message)
        normalized_message = message.to_s.downcase

        if normalized_message.include?("cannot operate between different countries")
          return "Country mismatch: collector account, plan, and payer/card token must belong to the same country/site. " \
                 "Ensure the account configured for site_id=#{account_value(:site_id) || "unknown"} in " \
                 "mercadopago_accounts has matching access_token, public_key, plan_id and currency for that country."
        end

        if normalized_message.include?("both payer and collector must be real or test users")
          return "Environment mismatch: do not mix TEST users/cards/tokens with APP_USR credentials. " \
                 "Use either all TEST-* credentials and test users, or all APP_USR-* with real users."
        end

        nil
      end

      def validate_credentials_consistency!
        access_token_mode = credential_mode(account_value(:access_token))
        public_key_mode = credential_mode(account_value(:public_key))

        return if access_token_mode == :unknown || public_key_mode == :unknown
        return if access_token_mode == public_key_mode

        raise "MercadoPago credentials mismatch: access_token is #{access_token_mode.upcase} and " \
              "public_key is #{public_key_mode.upcase} for site_id=#{account_value(:site_id) || "unknown"}. " \
              "Use both TEST-* or both APP_USR-* credentials."
      end

      def credential_mode(value)
        credential = value.to_s
        return :test if credential.start_with?("TEST-")
        return :production if credential.start_with?("APP_USR-")

        :unknown
      end

      def auth_headers
        token = account_value(:access_token).to_s
        raise "MercadoPago access token is missing for site_id=#{@site_id || "default"}. " \
              "Configure it in Admin → Settings → Monetization → mercadopago_accounts." if token.blank?

        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end

      def default_return_url
        resolve_back_url(nil)
      end

      def resolve_back_url(url)
        url = url.to_s.strip
        url = default_return_url if url.blank?

        unless url.match?(%r{\Ahttps?://})
          url = "#{base_url.chomp("/")}/#{url.delete_prefix("/")}"
        end

        raise "SiteSetting.base_url is not configured. Set it in Admin → Settings → General." if base_url.blank?
        url
      end

      def base_url
        SiteSetting.base_url.to_s.strip
      end

      def webhook_url
        raise "SiteSetting.base_url is not configured." if base_url.blank?
        "#{base_url.chomp("/")}/subscriptions/webhooks/#{provider_key}"
      end

      def cinelar_plan?(plan)
        return true if plan["id"].to_s == SiteSetting.mercadopago_plan_id.to_s

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
          back_url: resolve_back_url(success_url),
        }.compact

        "#{base}?#{URI.encode_www_form(params)}"
      end

      def configured_application_id
        account_value(:application_id).to_s.presence
      end

      def filter_plans_by_application(plans, application_id)
        return plans if application_id.blank?

        plans.select { |plan| plan["application_id"].to_s == application_id.to_s }
      end

      def mercadopago_host
        resolved_site_id = account_value(:site_id).to_s.upcase.presence || "MLU"

        case resolved_site_id
        when "MLA" then "mercadopago.com.ar"
        when "MLB" then "mercadopago.com.br"
        when "MLC" then "mercadopago.cl"
        when "MLM" then "mercadopago.com.mx"
        when "MPE" then "mercadopago.com.pe"
        when "MCO" then "mercadopago.com.co"
        else            "mercadopago.com.uy"
        end
      end

      # ── Account resolution ────────────────────────────────────────────────────
      #
      # Resolves the MercadoPago account to use for this provider instance.
      # If @site_id is set (e.g. via GeoIP), finds the matching enabled account.
      # Otherwise falls back to the first enabled account in the list.
      #
      # Returns nil if mercadopago_accounts is empty or unparseable.
      def resolve_account
        return @resolved_account if defined?(@resolved_account)

        raw = SiteSetting.mercadopago_accounts.to_s
        return (@resolved_account = nil) if raw.blank? || raw == "[]"

        accounts = JSON.parse(raw)
        @resolved_account = if @site_id.present?
          SiteSettings::MercadoPagoAccountsSchema.account_for(@site_id, accounts)
        else
          accounts.find { |a| a.is_a?(Hash) && a["enabled"] != false }
        end
      rescue JSON::ParserError
        @resolved_account = nil
      end

      # Returns the value of a field from the resolved account, or nil.
      def account_value(field)
        resolve_account&.dig(field.to_s)
      end

      # Resolves the webhook secret for incoming requests. For webhooks we cannot
      # know the site_id upfront, so we try the resolved account first and then
      # fall back to checking all enabled accounts (MP sends one webhook per account).
      def current_account_webhook_secret(request)
        # Prefer the already-resolved account's secret
        secret = account_value(:webhook_secret).to_s.presence
        return secret if secret.present?

        # If no site_id was set, check all accounts for one that has a secret
        all_accounts_secrets
      end

      def all_accounts_secrets
        raw = SiteSetting.mercadopago_accounts.to_s
        return nil if raw.blank?
        accounts = JSON.parse(raw)
        accounts.map { |a| a.is_a?(Hash) ? a["webhook_secret"].to_s.presence : nil }.compact.first
      rescue JSON::ParserError
        nil
      end
    end
  end
end
