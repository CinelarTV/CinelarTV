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

        # Require both v1 signature and timestamp for replay protection.
        return false if signature_parts[:v1].blank? || signature_parts[:ts].blank?

        request_id = request.headers["X-Request-Id"].to_s
        request_id = request.headers["x-request-id"].to_s if request_id.blank?
        data_id = request.query_parameters["data.id"].presence ||
                  request.query_parameters["id"].presence ||
                  parse_payload(request).dig("data", "id")

        manifest = webhook_manifest(data_id: data_id, request_id: request_id, ts: signature_parts[:ts])
        local_signature = OpenSSL::HMAC.hexdigest("SHA256", SiteSetting.mercadopago_webhook_secret, manifest)
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

      def create_subscription!(user:, success_url: nil, failure_url: nil, pending_url: nil, checkout_mode: nil, card_token_id: nil,
        start_date: nil, end_date: nil, amount: nil, currency_id: nil, frequency: nil, frequency_type: nil,
        repetitions: nil, billing_day: nil, billing_day_proportional: nil, purchase_token: nil, product_id: nil,
        package_name: nil, store: nil)
        plan_id = SiteSetting.mercadopago_plan_id.to_s
        validate_credentials_consistency!
        requested_checkout_mode = checkout_mode.to_s.presence

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

        if requires_card_token_fallback?(response, plan_id: plan_id, card_token_id: card_token_id)
          fallback_mode = requested_checkout_mode == "wallet_balance" ? "wallet_balance" : "provider_checkout"
          fallback_reason = requested_checkout_mode == "wallet_balance" ? "wallet_balance_checkout" : "card_token_required"

          return {
            provider: provider_key,
            checkout_url: plan_checkout_url(
              plan_id: plan_id,
              user: user,
              success_url: success_url
            ),
            preapproval_id: nil,
            plan_id: plan_id,
            checkout_mode: fallback_mode,
            fallback_reason: fallback_reason
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
          provider: provider_key,
          checkout_url: parsed["init_point"],
          preapproval_id: parsed["id"],
          plan_id: parsed["preapproval_plan_id"],
          checkout_mode: requested_checkout_mode || (card_token_id.present? ? "inline_card" : "provider_checkout")
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

        # When managed_only is true, only show plans that belong to this CinelarTV instance
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

      # Maps the raw preapproval Hash from fetch_subscription! to safe model
      # attributes. This is MercadoPago-specific: the preapproval object has
      # different field names than the UserSubscription columns.
      def normalize_remote_for_update(subscription, remote)
        raw_status    = remote["status"].to_s
        next_pay_date = parse_time(remote.dig("auto_recurring", "next_payment_date"))
        end_date      = parse_time(remote.dig("auto_recurring", "end_date"))

        {
          status:                  normalize_status(raw_status),
          status_formatted:        normalize_status(raw_status).humanize,
          external_status:         raw_status,
          renews_at:               next_pay_date || subscription.renews_at,
          ends_at:                 end_date,
          cancelled:               %w[cancelled canceled].include?(raw_status),
          user_email:              remote["payer_email"].presence ||
                                   remote.dig("payer", "email").presence ||
                                   subscription.user_email,
          metadata:                subscription.metadata.merge(
            "remote_sync" => remote.slice("status", "status_detail", "auto_recurring", "summarized"),
            "synced_at"   => Time.zone.now.iso8601
          )
        }.compact
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
          # Mercado Pago webhook test tool often sends placeholder IDs (for example 123456).
          if response.code == 404 || (response.code == 400 && body.include?("Subscription bad request"))
            raise ActiveRecord::RecordNotFound, "Preapproval not found for webhook id #{preapproval_id}"
          end

          raise "MercadoPago preapproval fetch error: #{body}"
        end

        JSON.parse(response.body)
      end

      # Fetches a single payment from the MP Payments API.
      # Payment objects always include preapproval_id, which we use to locate
      # the existing UserSubscription without relying on external_reference.
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

      # Processes a payment event from MP.
      #
      # Strategy for finding the subscription (in order):
      #   1. payment.preapproval_id → UserSubscription.provider_subscription_id
      #      This is the primary path — no external_reference needed since the
      #      subscription record was already created by the preapproval webhook.
      #   2. If not found locally, fetch the full preapproval and run the
      #      standard upsert path (which handles user lookup via external_reference).
      #
      # Status mapping:
      #   approved  → marks subscription active, updates renews_at
      #   rejected  → logs; MP will retry automatically, do NOT cancel the subscription
      #   refunded  → marks subscription cancelled
      def process_payment_event!(payment_id)
        payment = fetch_payment(payment_id)
        return if payment.blank?

        preapproval_id  = payment["preapproval_id"].to_s.presence
        payment_status  = payment["status"].to_s.downcase
        payment_amount  = payment["transaction_amount"]
        payment_currency = payment["currency_id"].to_s
        date_approved   = payment["date_approved"].to_s
        date_created    = payment["date_created"].to_s

        Rails.logger.info(
          "MercadoPago payment event payment_id=#{payment_id} preapproval_id=#{preapproval_id.presence || 'none'} " \
          "status=#{payment_status} amount=#{payment_amount} #{payment_currency}"
        )

        # --- 1. Find subscription by preapproval_id (primary path) ---
        subscription = preapproval_id.present? &&
          UserSubscription.find_by(provider: provider_key, provider_subscription_id: preapproval_id)

        # --- 2. Fallback: fetch preapproval and run full upsert ---
        if subscription.blank? && preapproval_id.present?
          Rails.logger.info(
            "MercadoPago payment #{payment_id}: subscription not found locally for preapproval #{preapproval_id}, " \
            "fetching preapproval to upsert"
          )
          preapproval_data = fetch_preapproval(preapproval_id)
          subscription = upsert_subscription_from_preapproval!(preapproval_data)
        end

        # If we still have no subscription, there's nothing we can do
        if subscription.blank?
          Rails.logger.warn(
            "MercadoPago payment #{payment_id}: could not find or create subscription " \
            "(preapproval_id=#{preapproval_id.presence || 'missing'}). Ignoring."
          )
          return
        end

        # --- 3. Update subscription based on payment outcome ---
        update_subscription_from_payment!(subscription, payment_status, payment, date_approved, date_created)
      end

      def update_subscription_from_payment!(subscription, payment_status, payment, date_approved, date_created)
        # Record the payment into the historical table
        record_payment_history(subscription, payment, payment_status, date_approved, date_created)

        case payment_status
        when "approved"
          # Payment successful: mark active and project next renewal date.
          # We use date_approved + subscription interval to estimate renews_at
          # since the preapproval next_payment_date may not have updated yet.
          new_renews_at = next_renewal_from_payment(subscription, date_approved)
          subscription.update!(
            status: "active",
            status_formatted: "Active",
            external_status: "approved",
            cancelled: false,
            renews_at: new_renews_at,
            metadata: subscription.metadata.merge(
              "last_payment_id"     => payment["id"].to_s,
              "last_payment_status" => payment_status,
              "last_payment_date"   => date_approved.presence || date_created,
              "last_payment_amount" => payment["transaction_amount"]
            )
          )
          Rails.logger.info(
            "MercadoPago payment approved: subscription #{subscription.id} renewed, next renewal ~#{new_renews_at}"
          )

        when "rejected", "cancelled"
          # MP retries automatically. We log but do NOT cancel the subscription —
          # a rejected payment doesn't mean the user cancelled; it means MP will retry.
          subscription.update!(
            metadata: subscription.metadata.merge(
              "last_payment_id"     => payment["id"].to_s,
              "last_payment_status" => payment_status,
              "last_payment_date"   => date_created,
              "last_payment_failure_detail" => payment.dig("status_detail")
            )
          )
          Rails.logger.info(
            "MercadoPago payment #{payment_status} for subscription #{subscription.id}: " \
            "MP will retry automatically. status_detail=#{payment.dig('status_detail')}"
          )

        when "refunded", "charged_back"
          subscription.update!(
            status: "cancelled",
            status_formatted: "Cancelled",
            external_status: payment_status,
            cancelled: true,
            cancelled_at: Time.zone.now,
            metadata: subscription.metadata.merge(
              "last_payment_id"     => payment["id"].to_s,
              "last_payment_status" => payment_status
            )
          )
          Rails.logger.info("MercadoPago payment refunded/charged_back: subscription #{subscription.id} cancelled")

        else
          # pending, in_process — intermediary states, just record them
          subscription.update!(
            metadata: subscription.metadata.merge(
              "last_payment_id"     => payment["id"].to_s,
              "last_payment_status" => payment_status
            )
          )
          Rails.logger.info(
            "MercadoPago payment #{payment_status} (intermediary) for subscription #{subscription.id}"
          )
        end
      end

      def record_payment_history(subscription, payment, payment_status, date_approved, date_created)
        payment_record = SubscriptionPayment.find_or_initialize_by(
          provider: provider_key,
          provider_payment_id: payment["id"].to_s
        )

        payment_record.update!(
          user_id: subscription.user_id,
          user_subscription_id: subscription.id,
          amount: payment["transaction_amount"] || 0.0,
          currency: payment["currency_id"] || "UYU",
          status: payment_status,
          paid_at: parse_time(date_approved) || parse_time(date_created),
          metadata: payment.slice("status_detail", "payment_method_id", "payment_type_id", "taxes_amount", "fee_details")
        )
      rescue StandardError => e
        Rails.logger.error("Failed to record payment history for #{payment["id"]}: #{e.message}")
      end

      # Estimates the next renewal date after a successful payment.
      # Reads the subscription's last known frequency from its metadata or falls
      # back to 1 month. This is only used until the next preapproval webhook
      # fires with the definitive next_payment_date.
      def next_renewal_from_payment(subscription, date_approved)
        base_date = parse_time(date_approved) || Time.zone.now

        # Try to get frequency from metadata (set during preapproval upsert)
        remote = subscription.metadata.dig("remote_sync") || subscription.metadata.dig("remote")
        frequency      = remote&.dig("auto_recurring", "frequency").to_i
        frequency_type = remote&.dig("auto_recurring", "frequency_type").to_s

        if frequency.positive? && frequency_type.present?
          case frequency_type
          when "days"   then base_date + frequency.days
          when "months" then base_date + frequency.months
          when "years"  then base_date + frequency.years
          else base_date + 1.month
          end
        else
          # Safe default: 1 month from payment date
          base_date + 1.month
        end
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
        return preapproval unless missing_preapproval_identifiers?(preapproval)

        searched = search_preapproval(preapproval_id: resource_id, application_id: application_id)
        return preapproval if searched.blank?

        preapproval.merge(searched)
      end

      def missing_preapproval_identifiers?(preapproval)
        external_reference = preapproval["external_reference"].to_s
        metadata_user_id = (preapproval["metadata"] || {})["user_id"].to_s
        payer_email = preapproval["payer_email"].presence || preapproval.dig("payer", "email").presence

        external_reference.blank? && metadata_user_id.blank? && payer_email.blank?
      end

      def upsert_subscription_from_preapproval!(preapproval)
        external_reference = preapproval["external_reference"].to_s
        metadata = preapproval["metadata"] || {}

        Rails.logger.info(
          "MercadoPago preapproval sync id=#{preapproval["id"]} application_id=#{preapproval["application_id"] || "unknown"} " \
          "external_reference=#{external_reference.presence || "none"} metadata_user_id=#{metadata["user_id"] || "none"} " \
          "payer_email=#{preapproval["payer_email"].presence || preapproval.dig("payer", "email").presence || "none"}"
        )

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
          checkout_reference: external_reference.presence || metadata["user_id"].presence || user.id,
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
          metadata: metadata.merge(preapproval.slice("status", "status_detail", "summarized", "operation_type", "auto_recurring"))
        )

        subscription
      end

      def find_user_for_preapproval(external_reference, metadata, preapproval)
        user_id = external_reference.presence || metadata["user_id"]
        return User.find_by(id: user_id) if user_id.present?

        existing_subscription = UserSubscription.find_by(
          provider: provider_key,
          provider_subscription_id: preapproval["id"].to_s
        )
        return existing_subscription.user if existing_subscription.present?

        pending_fallback_user = fallback_user_from_recent_pending_subscription(preapproval)
        return pending_fallback_user if pending_fallback_user.present?

        email = preapproval["payer_email"]
        return nil if email.blank?

        User.find_by(email: email)
      end

      def fallback_user_from_recent_pending_subscription(preapproval)
        scope = UserSubscription
          .where(provider: provider_key, status: "pending")
          .where(provider_subscription_id: [nil, ""])
          .where("updated_at >= ?", 30.minutes.ago)

        preapproval_plan_id = preapproval["preapproval_plan_id"].to_s
        scope = scope.where(provider_plan_id: preapproval_plan_id) if preapproval_plan_id.present?

        candidates = scope.order(updated_at: :desc).limit(2).to_a

        return nil unless candidates.size == 1

        candidates.first.user
      end

      def preapproval_payload_with_plan(user, plan_id:, success_url:, failure_url:, pending_url:, card_token_id:,
        start_date:, end_date:, amount:, currency_id:, frequency:, frequency_type:, repetitions:, billing_day:,
        billing_day_proportional:)
        # When using a preapproval plan, Mercado Pago validates recurring values
        # against the plan definition. Sending defaults here can trigger
        # "transaction_amount must be the same as preapproval_plan".
        auto_recurring_overrides = {
          frequency: frequency.presence&.to_i,
          frequency_type: frequency_type.presence,
          start_date: normalize_iso_datetime(start_date),
          end_date: normalize_iso_datetime(end_date),
          transaction_amount: amount.presence&.to_f,
          currency_id: currency_id.presence,
          repetitions: repetitions.presence&.to_i,
          billing_day: billing_day.presence&.to_i,
          billing_day_proportional: cast_boolean(billing_day_proportional)
        }.compact

        payload = {
          preapproval_plan_id: plan_id,
          reason: "CinelarTV Subscription",
          external_reference: user.id,
          payer_email: user.email,
          card_token_id: card_token_id.presence,
          back_url: success_url.presence || default_return_url,
          status: card_token_id.present? ? "authorized" : "pending",
          notification_url: webhook_url,
          auto_recurring: auto_recurring_overrides.presence,
          metadata: {
            user_id: user.id,
            site_id: SiteSetting.mercadopago_site_id.presence || "MLU",
            failure_url: failure_url,
            pending_url: pending_url
          }.compact
        }

        payload.compact
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

      def requires_card_token_fallback?(response, plan_id:, card_token_id:)
        return false if plan_id.blank? || card_token_id.present?
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
                 "Align mercadopago_access_token, mercadopago_public_key, mercadopago_plan_id and SiteSetting.mercadopago_site_id=" \
                 "#{SiteSetting.mercadopago_site_id}."
        end

        if normalized_message.include?("both payer and collector must be real or test users")
          return "Environment mismatch: do not mix TEST users/cards/tokens with APP_USR credentials. " \
                 "Use either all TEST-* credentials and test users, or all APP_USR-* with real users."
        end

        nil
      end

      def validate_credentials_consistency!
        access_token_mode = credential_mode(SiteSetting.mercadopago_access_token)
        public_key_mode = credential_mode(SiteSetting.mercadopago_public_key)

        return if access_token_mode == :unknown || public_key_mode == :unknown
        return if access_token_mode == public_key_mode

        raise "MercadoPago credentials mismatch: mercadopago_access_token is #{access_token_mode.upcase} and " \
              "mercadopago_public_key is #{public_key_mode.upcase}. Use both TEST-* or both APP_USR-* credentials."
      end

      def credential_mode(value)
        credential = value.to_s
        return :test if credential.start_with?("TEST-")
        return :production if credential.start_with?("APP_USR-")

        :unknown
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

      def configured_application_id
        SiteSetting.mercadopago_application_id.to_s.presence
      end

      def filter_plans_by_application(plans, application_id)
        return plans if application_id.blank?

        plans.select { |plan| plan["application_id"].to_s == application_id.to_s }
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
