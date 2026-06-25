# frozen_string_literal: true

require 'json'
require 'openssl'
require 'base64'
require 'net/http'
require 'uri'

module Subscriptions
  module Providers
    class GooglePlayProvider < BaseProvider
      def provider_key
        "google_play"
      end

      # Basic verification for Pub/Sub push: if a verification token is configured,
      # expect it in the `X-Play-Verification-Token` header. If not configured,
      # allow (validation must be tightened for production: OIDC JWT verification).
      def verify_webhook!(request)
        # Prefer explicit verification token if configured (simple case)
        token = SiteSetting.google_play_pubsub_verification_token.to_s.presence
        if token.present?
          header = request.headers['X-Play-Verification-Token'] || request.headers['X-PLAY-VERIFICATION-TOKEN']
          return ActiveSupport::SecurityUtils.secure_compare(header.to_s, token)
        end

        # Otherwise, attempt OIDC validation using Google's tokeninfo endpoint.
        auth = request.headers['Authorization'] || request.headers['authorization']
        return false if auth.blank?

        scheme, jwt = auth.to_s.split(" ", 2)
        return false unless scheme.to_s.downcase == 'bearer' && jwt.present?

        # Use Google's tokeninfo endpoint to validate the ID token.
        uri = URI.parse("https://oauth2.googleapis.com/tokeninfo?id_token=#{CGI.escape(jwt)}")
        res = Net::HTTP.get_response(uri)
        return false unless res.is_a?(Net::HTTPSuccess)

        body = JSON.parse(res.body) rescue {}
        iss = body['iss'] || body['issuer']
        aud = body['aud'] || body['audience']

        allowed_iss = ['https://accounts.google.com', 'accounts.google.com']
        return false unless iss.present? && allowed_iss.include?(iss)

        # If a webhook endpoint audience is configured, require it matches the token 'aud'
        expected_aud = SiteSetting.google_play_webhook_endpoint.to_s.presence
        if expected_aud.present?
          return false unless aud.to_s == expected_aud.to_s
        end

        true
      rescue StandardError => e
        Rails.logger.warn("#{self.class.name}#verify_webhook! failed: #{e.class} - #{e.message}")
        false
      end

      def fetch_subscription!(subscription)
        purchase_token = subscription.purchase_token
        product_id = subscription.google_product_id

        if purchase_token.blank? || product_id.blank?
          Rails.logger.warn("#{self.class.name}#fetch_subscription!: missing purchase_token or product_id for subscription #{subscription.id}")
          return nil
        end

        fetch_subscription_remote(product_id, purchase_token)
      end

      # Process incoming Pub/Sub push message or direct payload from client.
      # Expects either a JSON body with purchaseToken/subscriptionId or a wrapped
      # Pub/Sub message: { "message": { "data": "<base64>" } }
      def process_webhook!(request)
        body = request.raw_post.to_s
        payload = JSON.parse(body) rescue {}

        Rails.logger.info("#{self.class.name}#process_webhook! raw payload keys: #{payload.keys}")

        # Handle Pub/Sub push wrapper
        if payload['message'] && payload['message']['data']
          decoded = Base64.decode64(payload['message']['data']) rescue nil
          payload = JSON.parse(decoded) rescue payload
          Rails.logger.info("#{self.class.name}#process_webhook! decoded payload keys: #{payload.keys}")
        end

        # Extract purchaseToken and subscriptionId from subscriptionNotification
        if payload['subscriptionNotification']
          notification = payload['subscriptionNotification']
          purchase_token = notification['purchaseToken'] || notification['purchase_token']
          subscription_id = notification['subscriptionId'] || notification['subscription_id'] || notification['productId'] || notification['product_id']
          Rails.logger.info("#{self.class.name}#process_webhook! subscriptionNotification found: purchase_token=#{purchase_token}, subscription_id=#{subscription_id}")
        else
          purchase_token = payload['purchaseToken'] || payload['purchase_token']
          subscription_id = payload['subscriptionId'] || payload['subscription_id'] || payload['productId'] || payload['product_id']
          Rails.logger.info("#{self.class.name}#process_webhook! direct payload: purchase_token=#{purchase_token}, subscription_id=#{subscription_id}")
        end

        if purchase_token.present? && subscription_id.present?
          Rails.logger.info("#{self.class.name}#process_webhook! processing subscription: #{subscription_id}")
          
          # Re-validate with Google API and update local subscription
          remote = fetch_subscription_remote(subscription_id, purchase_token)
          Rails.logger.info("#{self.class.name}#process_webhook! remote data: #{remote&.keys}")
          return nil if remote.blank?

          # Find existing UserSubscription and update
          subscription = find_subscription_by_purchase_token_or_create(purchase_token, subscription_id, remote)
          Rails.logger.info("#{self.class.name}#process_webhook! found subscription: #{subscription&.id}")
          
          if subscription.present?
            # Update purchase_token if it changed (Google may issue new tokens)
            subscription.purchase_token = purchase_token if subscription.purchase_token != purchase_token

            normalized_data = normalize_remote_for_update(subscription, remote)
            Rails.logger.info("#{self.class.name}#process_webhook! normalized data: status=#{normalized_data[:status]}, cancelled=#{normalized_data[:cancelled]}")
            subscription.update!(normalized_data)
            Rails.logger.info("#{self.class.name}#process_webhook! subscription updated successfully")

            # Record payment history for active subscriptions
            record_payment_from_remote!(subscription, remote)
          else
            # Try to infer the user from payload/remote and create the subscription if possible
            user = find_user_for_subscription(remote, payload)
            if user.present?
              create_subscription_for_user(user, purchase_token, subscription_id, remote)
            else
              Rails.logger.info("#{self.class.name}#process_webhook!: no local subscription and no user mapping for purchase_token=#{purchase_token}")
            end
          end
        else
          Rails.logger.info("#{self.class.name}#process_webhook! received unsupported payload: #{payload.keys}")
        end

        true
      rescue StandardError => e
        Rails.logger.error("#{self.class.name}#process_webhook! error: #{e.class} - #{e.message}")
        raise
      end

      # Create a subscription record by validating the purchase token with Google
      # Expects keyword args including :_user (User instance), :_card_token_id is ignored
      def create_subscription!(user:, success_url: nil, failure_url: nil, pending_url: nil, checkout_mode: nil, card_token_id: nil,
        start_date: nil, end_date: nil, amount: nil, currency_id: nil, frequency: nil, frequency_type: nil,
        repetitions: nil, billing_day: nil, billing_day_proportional: nil, purchase_token: nil, product_id: nil, package_name: nil)
        # Support client-driven creation: requires purchase_token and product_id
        if purchase_token.present? && product_id.present?
          create_subscription_from_token!(user: user, product_id: product_id, purchase_token: purchase_token)
        else
          raise ArgumentError, "purchase_token and product_id are required for Google Play subscription creation"
        end
      end

      # Helper: create subscription using explicit purchase token and product id
      def create_subscription_from_token!(user:, product_id:, purchase_token:)
        remote = fetch_subscription_remote(product_id, purchase_token)
        raise StandardError, "Google Play validation failed" if remote.blank?

        subscription = user.user_subscriptions.find_or_initialize_by(purchase_token: purchase_token)
        subscription.google_product_id = product_id
        subscription.provider = provider_key
        subscription.assign_attributes(normalize_remote_for_update(subscription, remote))
        subscription.user_id ||= user.id if user.respond_to?(:id)
        subscription.save!

        # Record first payment for this subscription
        record_payment_from_remote!(subscription, remote)

        # Return a checkout-like hash expected by UserSubscriptionsController
        {
          subscription: subscription.as_json,
          plan_id: subscription.provider_plan_id,
          checkout_url: nil,
          checkout_mode: 'in_app',
          provider: provider_key
        }
      end

      # Fetches the subscription from Google Play API. For now this is a helper
      # that should implement the OAuth2 service account flow and call:
      # GET https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}
      def fetch_subscription_remote(subscription_id, purchase_token)
        sa_json = SiteSetting.google_play_service_account_json.to_s
        return nil if sa_json.blank?

        sa = JSON.parse(sa_json) rescue nil
        return nil if sa.blank?

        package_name = SiteSetting.google_play_package_name.to_s.presence || sa['package_name']
        token = access_token_for_service_account(sa)
        return nil if token.blank?

        url = URI.parse("https://androidpublisher.googleapis.com/androidpublisher/v3/applications/#{package_name}/purchases/subscriptions/#{subscription_id}/tokens/#{purchase_token}")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(url.request_uri)
        req['Authorization'] = "Bearer #{token}"
        req['Accept'] = 'application/json'

        resp = http.request(req)
        return nil if resp.code.to_i == 404

        if resp.code.to_i >= 200 && resp.code.to_i < 300
          body = JSON.parse(resp.body) rescue nil
          Rails.logger.info("#{self.class.name}#fetch_subscription_remote success: #{body.inspect}")
          body
        else
          Rails.logger.error("#{self.class.name}#fetch_subscription_remote HTTP #{resp.code}: #{resp.body}")
          nil
        end
      rescue StandardError => e
        Rails.logger.error("#{self.class.name}#fetch_subscription_remote error: #{e.class} - #{e.message}")
        nil
      end

      # Exchange service account JSON for an access token using JWT Bearer.
      # Caches the token globally (not per-instance) so all provider instances
      # reuse the same access token across requests and processes.
      def access_token_for_service_account(sa)
        client_email = sa['client_email']
        return nil if client_email.blank?

        cache_key = "google_play_service_account_token_#{Digest::SHA256.hexdigest(client_email)}"
        cached = Rails.cache.read(cache_key)
        return cached if cached.present?

        private_key = sa['private_key']
        token_uri = sa['token_uri'] || 'https://oauth2.googleapis.com/token'
        return nil if private_key.blank?

        now = Time.now.to_i
        payload = {
          iss: client_email,
          scope: 'https://www.googleapis.com/auth/androidpublisher',
          aud: token_uri,
          exp: now + 3600,
          iat: now
        }

        jwt = encode_jwt(payload, private_key)
        return nil if jwt.blank?

        uri = URI.parse(token_uri)
        req = Net::HTTP::Post.new(uri.request_uri)
        req.set_form_data({ 'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => jwt })
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        res = http.request(req)
        return nil unless res.code.to_i == 200

        body = JSON.parse(res.body) rescue nil
        return nil if body.blank? || body['access_token'].blank?

        expires_in = body['expires_in'] || 3600
        # Cache for slightly less than the actual expiry to avoid edge cases
        Rails.cache.write(cache_key, body['access_token'], expires_in: expires_in.to_i - 60)

        body['access_token']
      rescue StandardError => e
        Rails.logger.error("#{self.class.name}#access_token_for_service_account error: #{e.class} - #{e.message}")
        nil
      end

      def encode_jwt(payload, private_key_pem)
        header = { alg: 'RS256', typ: 'JWT' }
        segments = []
        segments << urlsafe_base64_encode(header.to_json)
        segments << urlsafe_base64_encode(payload.to_json)

        signing_input = segments.join('.')
        key = OpenSSL::PKey::RSA.new(private_key_pem)
        signature = key.sign(OpenSSL::Digest::SHA256.new, signing_input)
        segments << urlsafe_base64_encode(signature)
        segments.join('.')
      end

      def urlsafe_base64_encode(str)
        Base64.urlsafe_encode64(str).delete("=\n")
      end

      def normalize_remote_for_update(subscription, remote)
        raw_status = remote["paymentState"] || remote["status"]
        
        Rails.logger.info("#{self.class.name}#normalize_remote_for_update: remote data = #{remote.inspect}")
        
        # Map Google Play subscription states properly
        # paymentState values:
        # 0: Payment pending
        # 1: Payment received  
        # 2: Free trial
        # 3: Pending deferred upgrade/downgrade
        # null/undefined: Check expiry and autoRenewing status
        status = case remote["paymentState"]
        when 1, 2
          "active"
        when 0
          "pending"
        when 3
          "pending" # Pending deferred upgrade/downgrade
        when nil, ""
          # If paymentState is nil, check expiry and autoRenewing status
          expiry_ms = remote["expiryTimeMillis"]
          auto_renewing = remote["autoRenewing"]
          cancel_reason = remote["cancelReason"]
          
          Rails.logger.info("#{self.class.name}#normalize_remote_for_update: paymentState is nil, expiry_ms=#{expiry_ms}, auto_renewing=#{auto_renewing}, cancel_reason=#{cancel_reason}")
          
          if expiry_ms.present?
            expiry_time = Time.at(expiry_ms.to_i / 1000).utc
            
            Rails.logger.info("#{self.class.name}#normalize_remote_for_update: expiry_time=#{expiry_time}, current_time=#{Time.current.utc}")
            
            if expiry_time > Time.current.utc
              # Subscription is still within valid period
              if auto_renewing == false && cancel_reason.present?
                # User cancelled but subscription is still active until expiry
                "active" # Keep active until expiry date
              else
                "active"
              end
            else
              # Subscription has expired
              "cancelled"
            end
          else
            "active" # Assume active if no expiry info
          end
        else
          "active" # Default to active for unknown states
        end

        # Also consider acknowledgementState
        # 0: Yet to be acknowledged
        # 1: Acknowledged
        if remote["acknowledgementState"] == 0 && status == "active"
          # Keep as active - acknowledgement doesn't affect subscription status
          Rails.logger.info("#{self.class.name}#normalize_remote_for_update: Subscription not yet acknowledged but active")
        end

        expiry_ms = remote["expiryTimeMillis"]
        ends_at = expiry_ms.present? ? Time.at(expiry_ms.to_i / 1000).to_datetime : nil
        auto_renewing = remote["autoRenewing"]

        start_ms = remote["startTimeMillis"]
        starts_at = start_ms.present? ? Time.at(start_ms.to_i / 1000).to_datetime : nil

        cancel_ms = remote["userCancellationTimeMillis"]
        cancelled_at = cancel_ms.present? ? Time.at(cancel_ms.to_i / 1000).to_datetime : nil

        # Determine if subscription should be marked as cancelled in our system
        # Only mark as cancelled if actually expired, not just user-cancelled
        is_cancelled = status == "cancelled"

        # renews_at only applies to auto-renewing subscriptions
        renews_at = auto_renewing ? ends_at : nil

        {
          status: status,
          status_formatted: status.humanize,
          external_status: raw_status.to_s,
          ends_at: ends_at,
          renews_at: renews_at,
          cancelled: is_cancelled,
          cancelled_at: cancelled_at,
          external_id: remote["orderId"] || subscription.external_id,
          metadata: subscription.metadata.merge(
            "remote_sync" => remote,
            "synced_at" => Time.zone.now.iso8601,
            "auto_renewing" => remote["autoRenewing"],
            "cancel_reason" => remote["cancelReason"],
            "user_cancelled" => remote["autoRenewing"] == false && remote["cancelReason"].present?
          )
        }.compact
      end

      protected

      def find_subscription_by_purchase_token_or_create(purchase_token, product_id, remote)
        sub = UserSubscription.find_by(purchase_token: purchase_token)
        return sub if sub.present?

        # Try to find by external id in remote
        ext = remote['orderId'] || remote['purchaseToken']
        sub ||= UserSubscription.find_by(external_id: ext) if ext.present?
        
        # Try to find by google_product_id for Google Play subscriptions
        if product_id.present? && UserSubscription.column_names.include?('google_product_id')
          sub ||= UserSubscription.where(provider: 'google_play', google_product_id: product_id).order(created_at: :desc).first
        end

        # If still not found, try to find any Google Play subscription for this product that might be the same user
        # This handles cases where purchase_token changes but it's the same subscription
        if sub.blank? && product_id.present?
          sub ||= UserSubscription.where(provider: 'google_play')
                              .where("metadata->>'google_product_id' = ? OR google_product_id = ?", product_id, product_id)
                              .order(created_at: :desc)
                              .first
        end

        return sub if sub.present?

        # We cannot create a subscription without a user reference here; log and return nil.
        Rails.logger.info("#{self.class.name}#find_subscription_by_purchase_token_or_create: no local subscription found for purchase_token=#{purchase_token}, product_id=#{product_id}, external=#{ext}")
        nil
      end

      # Attempts to find a User from the webhook payload or remote data.
      # Looks for common fields: developerPayload (JSON), customData, email, or user_id.
      def find_user_for_subscription(remote, payload)
        # 1. developerPayload or customData: may contain JSON with user_id or email
        %w[developerPayload developer_payload developer_payload_json customData custom_data custom_payload].each do |k|
          next unless payload[k].present?
          begin
            parsed = JSON.parse(payload[k].to_s) rescue {}
            if parsed.is_a?(Hash)
              if parsed['user_id'].present?
                return User.find_by(id: parsed['user_id'])
              end
              if parsed['email'].present?
                return User.find_by(email: parsed['email'])
              end
            end
          rescue StandardError
            # ignore parse errors
          end
        end

        # 2. Remote fields from purchases.subscriptions.get
        if remote.is_a?(Hash)
          if remote['email'].present?
            return User.find_by(email: remote['email'])
          end

          # Some integrations set obfuscated ids; if you store them on User, try matching
          if remote['obfuscatedExternalAccountId'].present?
            col = :obfuscated_external_account_id
            return User.find_by(col => remote['obfuscatedExternalAccountId']) if User.column_names.include?(col.to_s)
          end
        end

        nil
      end

      # Create a linked UserSubscription for a given user from remote data
      def create_subscription_for_user(user, purchase_token, product_id, remote)
        sub = user.user_subscriptions.find_or_initialize_by(purchase_token: purchase_token)
        sub.google_product_id = product_id
        sub.provider = provider_key
        sub.external_id = remote['orderId'] if remote['orderId'].present?
        sub.assign_attributes(normalize_remote_for_update(sub, remote))
        sub.save!

        # Record first payment for this subscription
        record_payment_from_remote!(sub, remote)

        Rails.logger.info("#{self.class.name}#create_subscription_for_user: created subscription #{sub.id} for user #{user.id}")
        sub
      end

      # Create a SubscriptionPayment from Google Play remote data if the
      # subscription is active and we have payment information available.
      def record_payment_from_remote!(subscription, remote)
        order_id = remote["orderId"].to_s.presence
        return if order_id.blank?

        # Avoid duplicates for the same order
        return if SubscriptionPayment.exists?(provider: provider_key, provider_payment_id: order_id)

        # Extract payment details
        price_micros = remote["priceAmountMicros"]
        currency     = remote["priceCurrencyCode"].to_s.presence || "USD"
        amount       = price_micros.present? ? price_micros.to_f / 1_000_000 : nil

        paid_at = remote["purchaseTimeMillis"].present? ? Time.at(remote["purchaseTimeMillis"].to_i / 1000) : Time.zone.now

        # Only record payments for known-good statuses
        payment_state = remote["paymentState"]
        return unless [1, 2].include?(payment_state)  # 1=received, 2=free trial

        SubscriptionPayment.create!(
          user: subscription.user,
          user_subscription: subscription,
          provider: provider_key,
          provider_payment_id: order_id,
          amount: amount || 0,
          currency: currency,
          status: "approved",
          paid_at: paid_at,
          metadata: {
            "order_id" => order_id,
            "product_id" => remote["subscriptionId"] || subscription.google_product_id,
            "auto_renewing" => remote["autoRenewing"],
            "purchase_token" => subscription.purchase_token
          }
        )
        Rails.logger.info("#{self.class.name}#record_payment_from_remote!: created payment #{order_id} for subscription #{subscription.id}")
      rescue ActiveRecord::RecordNotUnique
        # Race condition: another webhook already recorded this payment
        Rails.logger.warn("#{self.class.name}#record_payment_from_remote!: duplicate payment #{order_id} skipped")
      end
    end
  end
end
