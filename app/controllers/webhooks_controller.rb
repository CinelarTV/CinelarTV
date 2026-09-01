# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:subscription]
  before_action :set_provider
  before_action :verify_signature, only: [:subscription]

  def subscription
    payload    = parse_payload
    if payload.blank?
      return render plain: "Empty body", status: :bad_request
    end

    event_name = request.headers["X-Topic"].presence ||
                 payload.dig("meta", "event_name").presence ||
                 payload["event_type"].presence ||
                 payload["type"].presence ||
                 "payment"

    # Snapshot request data before enqueuing — the request object is not
    # serializable and won't be available inside the Sidekiq job.
    snapshot = {
      "headers" => extract_webhook_headers,
      "body"    => request.raw_post.to_s,
      "params"  => request.query_parameters.to_h
    }

    resource_id = payload.dig("data", "id").presence ||
                  payload.dig("resource", "id").presence ||
                  payload["id"].presence ||
                  request.query_parameters["data.id"].presence
    event_id = payload["id"].presence || request.headers["X-Request-Id"].presence || request.headers["PAYPAL-TRANSMISSION-ID"].presence
    digest = Digest::SHA256.hexdigest(request.raw_post.to_s)
    event = ProviderEvent.find_or_create_by!(
      provider_key: provider_key, event_type: event_name, resource_id: resource_id,
      payload_sha256: digest
    ) do |record|
      record.provider_event_id = event_id
      record.resource_type = payload["resource_type"] || payload["type"]
      record.signature_valid = true
      record.received_at = Time.current
      record.payload = payload
      record.headers = extract_webhook_headers
    end

    ProcessSubscriptionWebhookJob.perform_async(provider_key, snapshot, event.id)

    # Respond immediately so MP / PayPal don't timeout and retry.
    render plain: "accepted", status: :accepted
  rescue StandardError => e
    Rails.logger.error("Subscription webhook enqueue error (#{provider_key}): #{e.class} - #{e.message}")
    render plain: "error", status: :unprocessable_entity
  end

  private

  def set_provider
    @provider = ::Subscriptions::Providers::Registry.build(provider_key)
  rescue ArgumentError
    render plain: "Unknown provider", status: :unprocessable_entity and return
  end

  def provider_key
    params[:provider].to_s
  end

  def verify_signature
    return if @provider.verify_webhook!(request)

    render plain: "Invalid signature", status: :unauthorized and return
  end

  def parse_payload
    JSON.parse(request.raw_post.to_s)
  rescue JSON::ParserError
    {}
  end

  # Snapshots only the headers that providers actually read during processing.
  # Keeping a lean subset avoids serializing large/irrelevant request metadata.
  def extract_webhook_headers
    relevant_keys = %w[
      X-Signature x-signature X-Provider-Signature
      X-Request-Id x-request-id
      X-Topic x-topic
      Content-Type
      Authorization
      PAYPAL-AUTH-ALGO paypal-auth-algo
      PAYPAL-CERT-URL paypal-cert-url
      PAYPAL-TRANSMISSION-ID paypal-transmission-id
      PAYPAL-TRANSMISSION-SIG paypal-transmission-sig
      PAYPAL-TRANSMISSION-TIME paypal-transmission-time
    ]

    relevant_keys.each_with_object({}) do |key, hash|
      value = request.headers[key].presence
      hash[key] = value if value
    end
  end
end
