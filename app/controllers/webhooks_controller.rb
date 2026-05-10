# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:subscription]
  before_action :set_provider
  before_action :verify_signature, only: [:subscription]

  def subscription
    payload    = parse_payload
    event_name = request.headers["X-Topic"].presence || payload["type"].presence || "payment"

    WebhookLog.create!(event_name: "#{provider_key}:#{event_name}", payload: payload.to_json)

    # Snapshot request data before enqueuing — the request object is not
    # serializable and won't be available inside the Sidekiq job.
    snapshot = {
      "headers" => extract_webhook_headers,
      "body"    => request.raw_post.to_s,
      "params"  => request.query_parameters.to_h
    }

    ProcessSubscriptionWebhookJob.perform_async(provider_key, snapshot)

    # Respond immediately so MP doesn't timeout and retry.
    render plain: "accepted", status: :accepted
  rescue StandardError => e
    Rails.logger.error("Subscription webhook enqueue error (#{provider_key}): #{e.class} - #{e.message}")
    render plain: "error", status: :unprocessable_entity
  end

  private

  def set_provider
    @provider = ::Subscriptions::Providers::Registry.build(provider_key)
  rescue ArgumentError
    render plain: "Unknown provider", status: :unprocessable_entity
  end

  def provider_key
    params[:provider].to_s
  end

  def verify_signature
    return if @provider.verify_webhook!(request)

    render plain: "Invalid signature", status: :unauthorized
  end

  def parse_payload
    payload = request.raw_post.to_s
    if payload.blank?
      render plain: "Invalid signature", status: :unauthorized
      return {}
    end

    JSON.parse(payload)
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
      X-Play-Verification-Token
      X-Goog-Channel-Token
    ]

    relevant_keys.each_with_object({}) do |key, hash|
      value = request.headers[key].presence
      hash[key] = value if value
    end
  end
end
