# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:subscription]
  before_action :set_provider
  before_action :verify_signature, only: [:subscription]

  def subscription
    payload = parse_payload
    event_name = request.headers["X-Topic"].presence || payload["type"].presence || "payment"

    WebhookLog.create!(event_name: "#{provider_key}:#{event_name}", payload: payload.to_json)

    @provider.process_webhook!(request)
    render plain: "ok", status: :ok
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("Webhook ignored: #{e.message}")
    render plain: "ignored", status: :accepted
  rescue StandardError => e
    Rails.logger.error("Subscription webhook error (#{provider_key}): #{e.class} - #{e.message}")
    render plain: "Invalid event", status: :unprocessable_entity
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
end
