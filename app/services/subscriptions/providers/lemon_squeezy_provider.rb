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

        external_id = if resource_type == "subscriptions"
                        data["id"].to_s
                      elsif resource_type == "subscription-invoices" || resource_type == "subscription-payments"
                        attributes["subscription_id"]&.to_s
                      end

        return if external_id.blank?

        # Find the Subscription in the new billing domain by provider_subscription_id
        subscription = Subscription.find_by(provider_key: provider_key, provider_subscription_id: external_id)

        if subscription.blank?
          Rails.logger.warn("Lemon Squeezy webhook: no matching Subscription for external_id #{external_id}")
          return
        end

        # Fetch fresh data from API
        remote_data = fetch_remote_subscription(subscription)
        return if remote_data.blank?

        # Apply via the new billing domain
        Billing::RemoteSnapshot.apply!(subscription:, remote: remote_data)
      end

      def start_checkout(subscription:, return_url:)
        plan_id = selected_plan_id
        raise "Lemon Squeezy plan id is missing" if plan_id.blank?

        store_id = SiteSetting.lemonsqueezy_store_id.to_s
        raise "Lemon Squeezy store id is missing" if store_id.blank?

        offering = Billing::Offering.current

        payload = checkout_payload(
          user: subscription.user,
          store_id: store_id,
          plan_id: plan_id,
          success_url: return_url,
          amount: offering.amount,
          external_reference: subscription.id
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
          redirect_url: checkout_url,
          provider_subscription_id: nil,
          provider_customer_id: nil,
          provider_plan_id: plan_id
        }
      end

      def fetch_remote_subscription(subscription)
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

      def cancel(subscription)
        return unless subscription.provider_subscription_id.present?

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

      def list_plans!(managed_only: true)
        query = { "page[size]" => 100 }

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

      def checkout_payload(user:, store_id:, plan_id:, success_url:, amount:, external_reference: nil)
        custom_data = { user_id: user.id, provider: provider_key, subscription_id: external_reference }.compact

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

      def normalize_remote_subscription(parsed)
        data = parsed["data"] || {}
        attributes = data["attributes"] || {}

        attributes.merge(
          "id" => data["id"],
          "status" => attributes["status"],
          "renews_at" => attributes["renews_at"],
          "ends_at" => attributes["ends_at"]
        )
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
                "Provider response: #{[title, detail].reject(&:blank?).join(" - ").presence || body}"
        end

        message = [title, detail].reject(&:blank?).join(" - ").presence || body
        raise "Lemon Squeezy #{action} error (#{response.code}): #{message}"
      end

      def default_return_url
        url = SiteSetting.base_url.to_s.strip
        raise "SiteSetting.base_url is not configured. Set it in Admin → Settings → General." if url.blank? || url.start_with?("/")
        "#{url.chomp("/")}/account/billing"
      end
    end
  end
end
