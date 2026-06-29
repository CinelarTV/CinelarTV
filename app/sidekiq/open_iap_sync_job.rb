# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

class OpenIapSyncJob
  include Sidekiq::Job
  sidekiq_options queue: :subscriptions, retry: 3

  # Syncs OpenIAP subscription states from Kit's REST API.
  # Kit receives Apple/Google webhooks directly and normalizes them.
  # We poll GET /v1/subscriptions/list/{apiKey} to stay in sync.
  def perform
    api_key = SiteSetting.open_iap_api_key.to_s
    return if api_key.blank?

    base_url = SiteSetting.open_iap_base_url.to_s.presence || "https://kit.openiap.dev"

    subscriptions = fetch_subscriptions(base_url, api_key)
    return if subscriptions.blank?

    Rails.logger.info("#{self.class.name}: Syncing #{subscriptions.size} OpenIAP subscriptions")

    synced = 0
    created = 0
    skipped = 0

    subscriptions.each do |remote_sub|
      result = sync_subscription(remote_sub)
      case result
      when :synced then synced += 1
      when :created then created += 1
      when :skipped then skipped += 1
      end
    end

    Rails.logger.info("#{self.class.name}: Done — #{synced} synced, #{created} created, #{skipped} skipped")
  end

  private

  def fetch_subscriptions(base_url, api_key)
    url = URI.parse("#{base_url}/v1/subscriptions/list/#{api_key}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == "https"
    http.open_timeout = 15
    http.read_timeout = 30

    req = Net::HTTP::Get.new(url.request_uri)
    req['Accept'] = 'application/json'

    resp = http.request(req)

    unless resp.code.to_i >= 200 && resp.code.to_i < 300
      Rails.logger.error("#{self.class.name}: HTTP #{resp.code} fetching subscriptions: #{resp.body}")
      return nil
    end

    parsed = JSON.parse(resp.body) rescue nil
    return nil if parsed.blank?

    # Kit returns either { subscriptions: [...] } or a bare array
    parsed.is_a?(Array) ? parsed : parsed["subscriptions"] || parsed["data"] || []
  rescue StandardError => e
    Rails.logger.error("#{self.class.name}: Error fetching subscriptions: #{e.class} — #{e.message}")
    nil
  end

  def sync_subscription(remote_sub)
    product_id = remote_sub["productId"] || remote_sub["product_id"]
    purchase_token = remote_sub["purchaseToken"] || remote_sub["purchase_token"]
    state = remote_sub["state"].to_s
    user_id = remote_sub["userId"] || remote_sub["user_id"]
    store = remote_sub["store"] || remote_sub["platform"]
    expires_at = parse_time(remote_sub["expiresAt"] || remote_sub["expires_at"])
    updated_at = parse_time(remote_sub["updatedAt"] || remote_sub["updated_at"])

    # Skip test transactions
    return :skipped if remote_sub["test"] == true || remote_sub["testMode"] == true

    # Find existing subscription by purchase_token (most reliable) or by product_id + user
    subscription = find_subscription(purchase_token, product_id, user_id)

    if subscription.blank?
      # Can't create without a linked user
      if user_id.blank? || user_id == "unbound"
        Rails.logger.warn("#{self.class.name}: Skipping unbound subscription — product=#{product_id} token=#{purchase_token&.truncate(20)}")
        return :skipped
      end

      user = find_user(user_id)
      if user.blank?
        Rails.logger.warn("#{self.class.name}: User not found for userId=#{user_id}, skipping subscription creation")
        return :skipped
      end

      subscription = create_subscription(user, product_id, purchase_token, store, state, expires_at)
      return :created if subscription
      return :skipped
    end

    # Update existing subscription
    new_status = normalize_kit_state(state)
    update_params = build_update_params(new_status, state, store, expires_at, updated_at, remote_sub)

    if subscription.status != new_status || needs_update?(subscription, update_params)
      subscription.update!(update_params)
      Rails.logger.info("#{self.class.name}: Updated subscription #{subscription.id} — #{subscription.status} -> #{new_status}")
      :synced
    else
      :skipped
    end
  rescue StandardError => e
    Rails.logger.error("#{self.class.name}: Error syncing subscription: #{e.class} — #{e.message}")
    :skipped
  end

  def find_subscription(purchase_token, product_id, user_id)
    # Primary lookup: by purchase_token (unique per transaction)
    if purchase_token.present?
      sub = UserSubscription.find_by(purchase_token: purchase_token, provider: "open_iap")
      return sub if sub
    end

    # Fallback: by iap_product_id + user binding
    if product_id.present? && user_id.present? && user_id != "unbound"
      user = find_user(user_id)
      if user
        sub = UserSubscription.where(user_id: user.id, provider: "open_iap", iap_product_id: product_id)
                              .order(updated_at: :desc)
                              .first
        return sub if sub
      end
    end

    nil
  end

  def find_user(user_id)
    return nil if user_id.blank? || user_id == "unbound"

    # Try UUID first, then external_id
    user = User.find_by(id: user_id)
    user ||= User.find_by(external_id: user_id)
    user
  end

  def create_subscription(user, product_id, purchase_token, store, state, expires_at)
    new_status = normalize_kit_state(state)

    subscription = UserSubscription.new(
      user_id: user.id,
      provider: "open_iap",
      purchase_token: purchase_token,
      iap_product_id: product_id,
      status: new_status,
      status_formatted: new_status.humanize,
      external_status: state,
      ends_at: expires_at,
      cancelled: %w[cancelled canceled expired revoked refunded].include?(new_status),
      cancelled_at: %w[cancelled canceled expired revoked refunded].include?(new_status) ? Time.zone.now : nil,
      metadata: {
        "store" => store,
        "synced_at" => Time.zone.now.iso8601,
        "open_iap_state" => state
      }
    )

    subscription.save!
    Rails.logger.info("#{self.class.name}: Created subscription #{subscription.id} for user #{user.id} — #{new_status}")
    subscription
  rescue StandardError => e
    Rails.logger.error("#{self.class.name}: Failed to create subscription: #{e.class} — #{e.message}")
    nil
  end

  def build_update_params(new_status, raw_state, store, expires_at, updated_at, remote_sub)
    params = {
      status: new_status,
      status_formatted: new_status.humanize,
      external_status: raw_state,
      metadata: {
        "store" => store,
        "synced_at" => Time.zone.now.iso8601,
        "open_iap_state" => raw_state,
        "remote_sync" => remote_sub
      }
    }

    # Update ends_at if we have a newer expiration
    params[:ends_at] = expires_at if expires_at.present?

    # Mark cancelled if state indicates it
    if %w[cancelled canceled expired revoked refunded].include?(new_status)
      params[:cancelled] = true
      params[:cancelled_at] ||= Time.zone.now
    elsif new_status == "active"
      params[:cancelled] = false
      params[:cancelled_at] = nil
    end

    params
  end

  # Maps Kit's normalized state names to our canonical statuses
  def normalize_kit_state(state)
    case state.to_s.upcase
    when "ACTIVE", "ENTITLED", "PENDING_ACKNOWLEDGMENT", "READY_TO_CONSUME", "IN_GRACE_PERIOD"
      "active"
    when "TRIALING", "TRIAL"
      "trialing"
    when "CANCELLED", "CANCELED", "EXPIRED", "REVOKED", "REFUNDED", "INAUTHENTIC"
      "cancelled"
    when "PENDING", "IN_BILLING_RETRY", "BILLING_RETRY"
      "pending"
    when "PAUSED"
      "past_due"
    else
      "active"
    end
  end

  def needs_update?(subscription, update_params)
    subscription.ends_at != update_params[:ends_at] ||
      subscription.external_status != update_params[:external_status]
  end

  def parse_time(value)
    return nil if value.blank?
    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
