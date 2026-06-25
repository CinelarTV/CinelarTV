# frozen_string_literal: true

module Subscriptions
  module Providers
    class LemonSqueezyProvider < BaseProvider
      API_BASE_URL = "https://api.lemonsqueezy.com/v1"

      def provider_key
        "lemon_squeezy"
      end

      def verify_webhook!(request)
        secret = SiteSetting.lemonsqueezy_webhook_secret.to_s
        return true if secret.blank?

        # Rails request.headers is case-insensitive
        signature = request.headers["X-Signature"].to_s
        return false if signature.blank?

        local_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post.to_s)
        secure_compare_hex(local_signature, signature)
      end

      def process_webhook!(request)
        payload = parse_payload(request)
        event_name = payload.dig("meta", "event_name").to_s
        data = payload.fetch("data", {})
        attributes = data["attributes"] || {}
        resource_type = data["type"]

        # 1. Identify Subscription ID and User
        external_id = if resource_type == "subscriptions"
                        data["id"].to_s
                      elsif resource_type == "subscription-invoices" || resource_type == "subscription-payments"
                        attributes["subscription_id"]&.to_s
                      end

        return if external_id.blank?

        custom_data = payload.dig("meta", "custom_data") || {}
        user = find_user_for_subscription(attributes: attributes, external_id: external_id, custom_data_from_meta: custom_data)

        if user.nil?
          Rails.logger.error("Lemon Squeezy webhook: User not found for subscription #{external_id}")
          raise ActiveRecord::RecordNotFound, "User not found for Lemon Squeezy subscription #{external_id}"
        end

        # 2. Find or Init local record
        subscription = UserSubscription.find_or_initialize_by(user_id: user.id)
        subscription.provider = provider_key
        subscription.provider_subscription_id = external_id
        subscription.save! if subscription.new_record?

        # 3. Perform a full fetch from API to get completion canonical data
        remote_data = fetch_subscription!(subscription)
        return if remote_data.blank?

        # 4. Sync local record
        update_params = normalize_remote_for_update(subscription, remote_data)
        
        # Merge some extra fields from webhook if needed (like trial info or checkout flags)
        update_params[:test_mode] = ActiveModel::Type::Boolean.new.cast(attributes["test_mode"]) if attributes.key?("test_mode")
        
        # Merge metadata
        existing_meta = subscription.metadata || {}
        update_params[:metadata] = existing_meta.merge(subscription_metadata(attributes, event_name: event_name))

        subscription.update!(update_params)
      end

      def create_subscription!(user:, success_url: nil, failure_url: nil, pending_url: nil, checkout_mode: nil, card_token_id: nil,
        start_date: nil, end_date: nil, amount: nil, currency_id: nil, frequency: nil, frequency_type: nil,
        repetitions: nil, billing_day: nil, billing_day_proportional: nil)
        plan_id = selected_plan_id
        raise "Lemon Squeezy plan id is missing" if plan_id.blank?

        store_id = SiteSetting.lemonsqueezy_store_id.to_s
        raise "Lemon Squeezy store id is missing" if store_id.blank?

        payload = checkout_payload(
          user: user,
          store_id: store_id,
          plan_id: plan_id,
          success_url: success_url,
          failure_url: failure_url,
          pending_url: pending_url,
          checkout_mode: checkout_mode,
          amount: amount
        )

        response = HTTParty.post(
          "#{API_BASE_URL}/checkouts",
          headers: auth_headers,
          body: payload.to_json
        )

        raise_api_error!(response, action: "checkout create") unless response.code.between?(200, 299)

        parsed = parse_json(response.body)
        checkout_id = parsed.dig("data", "id").to_s
        checkout_url = parsed.dig("data", "attributes", "url").to_s
        raise "Lemon Squeezy checkout ID is missing" if checkout_id.blank?

        {
          provider: provider_key,
          checkout_id: checkout_id,
          checkout_url: checkout_url,
          preapproval_id: nil,
          plan_id: plan_id,
          checkout_mode: "provider_checkout"
        }
      end

      alias create_checkout! create_subscription!

      def fetch_subscription!(subscription)
        return nil if subscription.provider_subscription_id.blank?

        response = HTTParty.get(
          "#{API_BASE_URL}/subscriptions/#{subscription.provider_subscription_id}",
          headers: auth_headers
        )

        if response.code == 404
          raise ActiveRecord::RecordNotFound, "Lemon Squeezy subscription not found: #{subscription.provider_subscription_id}"
        end

        raise_api_error!(response, action: "subscription fetch") unless response.code.between?(200, 299)

        normalize_remote_subscription(parse_json(response.body))
      end

      def cancel_subscription!(subscription)
        if subscription.provider_subscription_id.present?
          body = {
            data: {
              type: "subscriptions",
              id: subscription.provider_subscription_id.to_s,
              attributes: { cancelled: true }
            }
          }

          response = HTTParty.patch(
            "#{API_BASE_URL}/subscriptions/#{subscription.provider_subscription_id}",
            headers: auth_headers,
            body: body.to_json
          )

          raise_api_error!(response, action: "subscription cancel") unless response.code.between?(200, 299)
        end

        subscription.update!(
          status: "cancelled",
          external_status: "cancelled_by_admin",
          cancelled: true,
          cancelled_at: Time.zone.now
        )
      end

      def list_plans!(managed_only: true)
        query = { "page[size]" => 100 }
        store_id = SiteSetting.lemonsqueezy_store_id.to_s.presence
        query["filter[store_id]"] = store_id if store_id.present?

        response = HTTParty.get(
          "#{API_BASE_URL}/variants?#{URI.encode_www_form(query)}",
          headers: auth_headers
        )

        raise_api_error!(response, action: "plans fetch") unless response.code.between?(200, 299)

        parsed = parse_json(response.body)
        plans = (parsed["data"] || []).filter_map { |variant| plan_from_variant(variant) }

        if managed_only
          selected_id = selected_plan_id
          plans = plans.select do |plan|
            plan_status = plan["status"].to_s.downcase
            plan["id"].to_s == selected_id.to_s || %w[published active].include?(plan_status)
          end
        end

        { "results" => plans }
      end

      def create_plan!(_params)
        raise "Lemon Squeezy plans must be managed in Lemon Squeezy dashboard"
      end

      def update_plan!(_plan_id, _params)
        raise "Lemon Squeezy plans must be managed in Lemon Squeezy dashboard"
      end

      def deactivate_plan!(_plan_id)
        raise "Lemon Squeezy plans must be managed in Lemon Squeezy dashboard"
      end

      def normalize_remote_for_update(subscription, remote)
        raw_status = remote["status"].to_s
        new_status = normalize_status(raw_status)
        
        {
          status: new_status,
          status_formatted: new_status.humanize,
          external_status: raw_status,
          provider_customer_id: remote["customer_id"]&.to_s || subscription.provider_customer_id,
          provider_plan_id: remote["variant_id"]&.to_s || subscription.provider_plan_id,
          order_id: integer_or_nil(remote["order_id"]) || subscription.order_id,
          order_item_id: integer_or_nil(remote["order_item_id"]) || subscription.order_item_id,
          product_id: integer_or_nil(remote["product_id"]) || subscription.product_id,
          variant_id: integer_or_nil(remote["variant_id"]) || subscription.variant_id,
          product_name: remote["product_name"].presence || subscription.product_name || "Subscription",
          variant_name: remote["variant_name"].presence || subscription.variant_name,
          user_name: remote["user_name"].presence || subscription.user_name,
          user_email: remote["user_email"].presence || subscription.user_email,
          card_brand: remote["card_brand"] || subscription.card_brand,
          card_last_four: remote["card_last_four"] || subscription.card_last_four,
          renews_at: parse_time(remote["renews_at"]) || subscription.renews_at,
          ends_at: parse_time(remote["ends_at"]) || subscription.ends_at,
          cancelled: cancelled_subscription?(raw_status, remote),
          cancelled_at: parse_time(remote["ends_at"]),
          trial_ends_at: parse_time(remote["trial_ends_at"]) || subscription.trial_ends_at,
          billing_anchor: integer_or_nil(remote["billing_anchor"]) || subscription.billing_anchor,
          metadata: (subscription.metadata || {}).merge(
            "remote_sync" => remote.slice("status", "renews_at", "ends_at", "urls", "cancelled", "trial_ends_at"),
            "synced_at"   => Time.zone.now.iso8601
          )
        }.compact
      end

      private

      def checkout_payload(user:, store_id:, plan_id:, success_url:, failure_url:, pending_url:, checkout_mode:, amount:)
        custom_data = { user_id: user.id, provider: provider_key }
        custom_data[:checkout_mode] = checkout_mode.to_s if checkout_mode.present?
        custom_data[:failure_url]   = failure_url.to_s   if failure_url.present?
        custom_data[:pending_url]   = pending_url.to_s   if pending_url.present?

        attributes = {
          checkout_data: {
            email: user.email,
            custom: custom_data
          },
          checkout_options: {
            embed: false,
            media: true,
            logo: true
          },
          product_options: {
            redirect_url: success_url.presence || default_return_url,
            receipt_link_url: default_return_url,
            receipt_button_text: "Manage Subscription"
          }
        }

        custom_price = (amount.to_f * 100).round
        attributes[:custom_price] = custom_price if amount.present? && custom_price.positive?

        {
          data: {
            type: "checkouts",
            attributes: attributes,
            relationships: {
              store: { data: { type: "stores", id: store_id.to_s } },
              variant: { data: { type: "variants", id: plan_id.to_s } }
            }
          }
        }
      end

      # (upsert_subscription_from_webhook! removed in favor of full sync)

      def find_user_for_subscription(attributes:, external_id:, custom_data_from_meta: {})
        # First priority: custom_data from webhook meta (most reliable)
        user_id = custom_data_from_meta["user_id"].presence
        return User.find_by(id: user_id) if user_id.present?

        # Fallback: custom_data embedded in subscription attributes
        user_id = attributes.dig("custom_data", "user_id").presence ||
                  attributes.dig("checkout_data", "custom", "user_id").presence
        return User.find_by(id: user_id) if user_id.present?

        # Fallback: find existing subscription by external id
        existing = UserSubscription.find_by(provider: provider_key, provider_subscription_id: external_id)
        return existing.user if existing.present?

        # Fallback: find by email
        email = attributes["user_email"].presence || attributes.dig("customer", "email").presence
        return User.find_by(email: email) if email.present?

        # Last resort: recent pending subscription with matching plan
        fallback_user_from_recent_pending_subscription(attributes)
      end

      def fallback_user_from_recent_pending_subscription(attributes)
        timeout_minutes = SiteSetting.lemonsqueezy_pending_lookup_minutes.to_i
        timeout_minutes = 30 if timeout_minutes <= 0

        scope = UserSubscription
          .where(provider: provider_key, status: "pending")
          .where(provider_subscription_id: [nil, ""])
          .where("updated_at >= ?", timeout_minutes.minutes.ago)

        variant_id = attributes["variant_id"].to_s
        scope = scope.where(provider_plan_id: variant_id) if variant_id.present?

        candidates = scope.order(updated_at: :desc).limit(2).to_a
        return nil unless candidates.size == 1

        candidates.first.user
      end

      def subscription_metadata(attributes, event_name:)
        # URL keys match exactly what the LS API returns in the `urls` object
        urls = attributes["urls"].is_a?(Hash) ? attributes["urls"] : {}

        metadata = {
          "event_name"                           => event_name,
          "customer_portal"                      => urls["customer_portal"],
          "update_payment_method_url"            => urls["update_payment_method"],
          "customer_portal_update_subscription"  => urls["customer_portal_update_subscription"],
          "store_id"                             => attributes["store_id"],
          "customer_id"                          => attributes["customer_id"],
          "status_formatted"                     => attributes["status_formatted"]
        }

        metadata["custom_data"] = attributes["custom_data"] if attributes["custom_data"].is_a?(Hash)
        metadata.compact
      end

      def cancelled_subscription?(raw_status, attributes)
        return true if ActiveModel::Type::Boolean.new.cast(attributes["cancelled"])

        %w[cancelled canceled expired unpaid].include?(raw_status.to_s.downcase)
      end

      def normalize_remote_subscription(parsed)
        data = parsed["data"] || {}
        attributes = data["attributes"] || {}

        attributes.merge(
          "id" => data["id"],
          "status" => attributes["status"],
          "urls" => attributes["urls"] || {}
        )
      end

      def plan_from_variant(variant)
        attrs = variant["attributes"] || {}
        interval_count = [attrs["interval_count"].to_i, 1].max

        {
          "id" => variant["id"].to_s,
          "reason" => attrs["name"].presence || "Variant #{variant["id"]}",
          "status" => attrs["status"],
          "auto_recurring" => {
            "transaction_amount" => variant_amount(attrs),
            "currency_id" => attrs["currency"].to_s.upcase.presence || "USD",
            "frequency" => interval_count,
            "frequency_type" => interval_to_frequency_type(attrs["interval"])
          }
        }
      end

      def variant_amount(attrs)
        if attrs["price"].present?
          attrs["price"].to_f / 100.0
        elsif attrs["price_usd"].present?
          attrs["price_usd"].to_f
        else
          0.0
        end
      end

      def interval_to_frequency_type(interval)
        case interval.to_s
        when "day"   then "days"
        when "week"  then "weeks"
        when "month" then "months"
        when "year"  then "years"
        else              "months"
        end
      end

      def integer_or_nil(value)
        value.blank? ? nil : value.to_i
      end

      def selected_plan_id
        SiteSetting.lemon_squeezy_plan_id.to_s.presence
      end

      def parse_payload(request)
        parse_json(request.raw_post.to_s)
      end

      def parse_json(value)
        JSON.parse(value.to_s)
      rescue JSON::ParserError
        {}
      end

      def secure_compare_hex(a, b)
        a_s = a.to_s.downcase
        b_s = b.to_s.downcase
        return false if a_s.blank? || b_s.blank? || a_s.bytesize != b_s.bytesize

        ActiveSupport::SecurityUtils.secure_compare(a_s, b_s)
      end

      def auth_headers
        token = lemon_api_key
        raise "Lemon Squeezy API key is missing" if token.blank?

        {
          "Authorization" => "Bearer #{token}",
          "Accept" => "application/vnd.api+json",
          "Content-Type" => "application/vnd.api+json"
        }
      end

      def lemon_api_key
        SiteSetting.lemonsqueezy_api_key.to_s.strip.sub(/\ABearer\s+/i, "")
      end

      def raise_api_error!(response, action:)
        body = response.body.to_s
        parsed = parse_json(body)
        first_error = (parsed["errors"] || []).first || {}
        detail = first_error["detail"].to_s
        title = first_error["title"].to_s

        Rails.logger.error("Lemon Squeezy API error during #{action}: HTTP #{response.code}. Response body: #{body}")

        if response.code.to_i == 401
          raise "Lemon Squeezy #{action} error (401 Unauthorized). " \
                "Verify SiteSetting.lemonsqueezy_api_key contains a valid JWT token (starts with 'eyJ'). " \
                "#{api_key_debug_hint} " \
                "Provider response: #{[title, detail].reject(&:blank?).join(" - ").presence || body}"
        end

        message = [title, detail].reject(&:blank?).join(" - ").presence || body
        raise "Lemon Squeezy #{action} error (#{response.code}): #{message}"
      end

      def api_key_debug_hint
        token = lemon_api_key
        return "No API key found in SiteSetting.lemonsqueezy_api_key." if token.blank?

        masked = token.length <= 8 ? "***" : "#{token[0, 4]}...#{token[-4, 4]}"

        unless token =~ /\AeyJ/i
          return "Loaded key=#{masked} len=#{token.length}. ⚠️ Unexpected format — Lemon Squeezy API keys are JWT tokens starting with 'eyJ'."
        end

        hint = "✓ Valid JWT format."

        parts = token.split(".")
        if parts.length == 3
          begin
            payload = JSON.parse(Base64.urlsafe_decode64("#{parts[1]}=="))
            if payload["exp"].present?
              exp_time = Time.at(payload["exp"])
              hint += payload["exp"] < Time.now.to_i ? " ⚠️ Token EXPIRED (#{exp_time})." : " (expires: #{exp_time})."
            end
          rescue StandardError
            # Non-critical: skip expiry check if JWT can't be decoded
          end
        else
          hint += " ⚠️ Invalid JWT structure (expected 3 parts, got #{parts.length})."
        end

        "Loaded key=#{masked} len=#{token.length}. #{hint}"
      end

      def default_return_url
        "#{SiteSetting.base_url}/account/billing"
      end
    end
  end
end