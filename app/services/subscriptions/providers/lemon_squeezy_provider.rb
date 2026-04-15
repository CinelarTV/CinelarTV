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

        signature = request.headers["X-Signature"].to_s
        signature = request.headers["x-signature"].to_s if signature.blank?
        return false if signature.blank?

        local_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post.to_s)
        secure_compare_hex(local_signature, signature)
      end

      def process_webhook!(request)
        payload = parse_payload(request)
        event_name = payload.dig("meta", "event_name").to_s
        event_name = payload["event_name"].to_s if event_name.blank?
        event_name = payload["type"].to_s if event_name.blank?

        case event_name
        when /\Asubscription_/
          upsert_subscription_from_webhook!(payload.fetch("data", {}), event_name: event_name)
        when "order_created"
          Rails.logger.info("Lemon Squeezy order_created event received")
        else
          Rails.logger.warn("Unknown Lemon Squeezy event type: #{event_name}")
        end
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
        checkout_url = parsed.dig("data", "attributes", "url").to_s
        raise "Lemon Squeezy checkout URL is missing" if checkout_url.blank?

        {
          provider: provider_key,
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
              attributes: {
                cancelled: true
              }
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

      private

      def checkout_payload(user:, store_id:, plan_id:, success_url:, failure_url:, pending_url:, checkout_mode:, amount:)
        custom_data = {
          user_id: user.id,
          provider: provider_key
        }

        custom_data[:checkout_mode] = checkout_mode if checkout_mode.present?
        custom_data[:failure_url] = failure_url if failure_url.present?
        custom_data[:pending_url] = pending_url if pending_url.present?

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
              store: {
                data: {
                  type: "stores",
                  id: store_id.to_s
                }
              },
              variant: {
                data: {
                  type: "variants",
                  id: plan_id.to_s
                }
              }
            }
          }
        }
      end

      def upsert_subscription_from_webhook!(data, event_name:)
        raise ArgumentError, "Missing Lemon Squeezy subscription payload" if data.blank?

        attributes = data["attributes"] || {}
        external_id = data["id"].to_s
        raise ArgumentError, "Missing Lemon Squeezy subscription id" if external_id.blank?

        user = find_user_for_subscription(attributes: attributes, external_id: external_id)
        raise ActiveRecord::RecordNotFound, "User not found for Lemon Squeezy subscription #{external_id}" if user.nil?

        raw_status = attributes["status"].to_s
        status = normalize_status(raw_status)
        cancelled = cancelled_subscription?(raw_status, attributes)

        subscription = UserSubscription.find_or_initialize_by(user_id: user.id)
        subscription.update!(
          provider: provider_key,
          provider_subscription_id: external_id,
          provider_customer_id: attributes["customer_id"]&.to_s,
          provider_plan_id: attributes["variant_id"]&.to_s || selected_plan_id,
          checkout_reference: attributes.dig("custom_data", "user_id").presence || user.id,
          order_id: integer_or_nil(attributes["order_id"]),
          order_item_id: integer_or_nil(attributes["order_item_id"]),
          product_id: integer_or_nil(attributes["product_id"]),
          variant_id: integer_or_nil(attributes["variant_id"]),
          product_name: attributes["product_name"].presence || "Subscription",
          variant_name: attributes["variant_name"].presence || attributes["variant_id"]&.to_s,
          user_name: attributes["user_name"].presence || user.username,
          user_email: attributes["user_email"].presence || user.email,
          status: status,
          status_formatted: status.humanize,
          external_status: raw_status,
          card_brand: attributes["card_brand"],
          card_last_four: attributes["card_last_four"],
          cancelled: cancelled,
          cancelled_at: cancelled ? (parse_time(attributes["ends_at"]) || Time.zone.now) : nil,
          trial_ends_at: parse_time(attributes["trial_ends_at"]),
          billing_anchor: integer_or_nil(attributes["billing_anchor"]),
          renews_at: parse_time(attributes["renews_at"]),
          ends_at: parse_time(attributes["ends_at"]),
          test_mode: ActiveModel::Type::Boolean.new.cast(attributes["test_mode"]),
          metadata: (subscription.metadata || {}).merge(subscription_metadata(attributes, event_name: event_name))
        )

        subscription
      end

      def find_user_for_subscription(attributes:, external_id:)
        user_id = attributes.dig("custom_data", "user_id").presence || attributes.dig("checkout_data", "custom", "user_id").presence
        return User.find_by(id: user_id) if user_id.present?

        existing_subscription = UserSubscription.find_by(
          provider: provider_key,
          provider_subscription_id: external_id
        )
        return existing_subscription.user if existing_subscription.present?

        email = attributes["user_email"].presence || attributes.dig("customer", "email").presence
        return User.find_by(email: email) if email.present?

        fallback_user_from_recent_pending_subscription(attributes)
      end

      def fallback_user_from_recent_pending_subscription(attributes)
        scope = UserSubscription
          .where(provider: provider_key, status: "pending")
          .where(provider_subscription_id: [nil, ""])
          .where("updated_at >= ?", 30.minutes.ago)

        variant_id = attributes["variant_id"].to_s
        scope = scope.where(provider_plan_id: variant_id) if variant_id.present?

        candidates = scope.order(updated_at: :desc).limit(2).to_a
        return nil unless candidates.size == 1

        candidates.first.user
      end

      def subscription_metadata(attributes, event_name:)
        urls = attributes["urls"].is_a?(Hash) ? attributes["urls"] : {}

        metadata = {
          "event_name" => event_name,
          "customer_portal_url" => urls["customer_portal"],
          "portal_url" => urls["customer_portal"],
          "manage_url" => urls["customer_portal"],
          "management_url" => urls["customer_portal"],
          "update_payment_method_url" => urls["update_payment_method"],
          "customer_portal_update_subscription" => urls["customer_portal_update_subscription"],
          "customer_portal_invoice_url" => urls["customer_portal_invoice_url"],
          "store_id" => attributes["store_id"],
          "customer_id" => attributes["customer_id"],
          "status_formatted" => attributes["status_formatted"]
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
        interval_count = attrs["interval_count"].to_i
        interval_count = 1 unless interval_count.positive?

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
        when "day"
          "days"
        when "week"
          "weeks"
        when "month"
          "months"
        when "year"
          "years"
        else
          "months"
        end
      end

      def integer_or_nil(value)
        return nil if value.blank?

        value.to_i
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
        raw = if SiteSetting.respond_to?(:lemonsqueezy_api_key)
                SiteSetting.lemonsqueezy_api_key
              elsif SiteSetting.respond_to?(:lemon_squeezy_api_key)
                SiteSetting.lemon_squeezy_api_key
              end

        raw = ENV["LEMONSQUEEZY_API_KEY"] if raw.to_s.strip.blank?
        raw = ENV["LEMON_SQUEEZY_API_KEY"] if raw.to_s.strip.blank?

        token = raw.to_s.strip
        token = token.sub(/\ABearer\s+/i, "")
        token = token.sub(/\A['\"]/, "").sub(/['\"]\z/, "")
        token = token.gsub(/\s+/, "")
        token
      end

      def raise_api_error!(response, action:)
        body = response.body.to_s
        parsed = parse_json(body)
        first_error = (parsed["errors"] || []).first || {}
        detail = first_error["detail"].to_s
        title = first_error["title"].to_s

        if response.code.to_i == 401
            key_hint = api_key_debug_hint
          raise "Lemon Squeezy #{action} error (401 Unauthorized). Verify SiteSetting.lemonsqueezy_api_key " \
              "with a valid API key (usually sk_... or ls_api_...), do not include the 'Bearer' prefix, and do not use the webhook secret. " \
              "#{key_hint} " \
                "Provider response: #{[title, detail].reject(&:blank?).join(' - ').presence || body}"
        end

        message = [title, detail].reject(&:blank?).join(" - ").presence || body
        raise "Lemon Squeezy #{action} error (#{response.code}): #{message}"
      end

      def api_key_debug_hint
        token = lemon_api_key
        return "No API key value detected in settings or env vars." if token.blank?

        masked = if token.length <= 8
                   "***"
                 else
                   "#{token[0, 4]}...#{token[-4, 4]}"
                 end

        "Loaded key=#{masked} len=#{token.length}."
      end

      def default_return_url
        "#{SiteSetting.base_url}/account/billing"
      end
    end
  end
end