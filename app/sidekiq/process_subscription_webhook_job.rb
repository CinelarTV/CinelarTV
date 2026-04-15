# frozen_string_literal: true

# Processes a subscription webhook from any provider asynchronously.
#
# This job is enqueued by WebhooksController immediately after signature
# verification and logging. Responding quickly (202 Accepted) to MP prevents
# timeout-triggered retries and duplicate processing.
#
# The request data is snapshotted as a plain Hash so it survives serialization:
#   - headers: the relevant webhook headers
#   - body:    the raw request body (already validated at enqueue time)
#   - params:  query string parameters (MP sometimes puts data.id here)
class ProcessSubscriptionWebhookJob
  include Sidekiq::Job

  sidekiq_options queue: :subscriptions, retry: 3

  # @param provider_key [String]  e.g. "mercado_pago"
  # @param snapshot     [Hash]    { "headers" => {}, "body" => "", "params" => {} }
  def perform(provider_key, snapshot)
    provider = ::Subscriptions::Providers::Registry.build(provider_key)
    request  = WebhookRequestSnapshot.new(snapshot)

    provider.process_webhook!(request)
  rescue ActiveRecord::RecordNotFound => e
    # Subscription or user not found — ignore silently (already logged in provider)
    Rails.logger.warn("ProcessSubscriptionWebhookJob ignored: #{e.message}")
  rescue StandardError => e
    Rails.logger.error(
      "ProcessSubscriptionWebhookJob failed for #{provider_key}: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    )
    raise # Re-raise so Sidekiq retries
  end
end

# Lightweight struct that mimics the ActionDispatch::Request interface used
# inside the provider's process_webhook! and verify_webhook! methods.
# Only exposes what the providers actually read.
class WebhookRequestSnapshot
  def initialize(snapshot)
    @headers = snapshot["headers"] || {}
    @body    = snapshot["body"].to_s
    @params  = snapshot["params"] || {}
  end

  # ActionDispatch::Request#headers interface
  def headers
    @headers
  end

  # ActionDispatch::Request#raw_post
  def raw_post
    @body
  end

  # ActionDispatch::Request#query_parameters
  def query_parameters
    @params
  end
end
