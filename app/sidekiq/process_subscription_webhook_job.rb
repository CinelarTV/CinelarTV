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

# Wraps a plain Hash to provide case-insensitive header lookups,
# matching ActionDispatch::Http::Headers behavior.
class CaseInsensitiveHeadersHash
  def initialize(hash)
    @store = hash.to_h { |k, v| [k.to_s.downcase, v] }
  end

  def [](key)
    @store[key.to_s.downcase]
  end

  def dig(key, *args)
    @store.dig(key.to_s.downcase, *args)
  end

  def fetch(key, *args, &block)
    @store.fetch(key.to_s.downcase, *args, &block)
  end

  def key?(key)
    @store.key?(key.to_s.downcase)
  end

  def each(&block)
    @store.each(&block)
  end

  def empty?
    @store.empty?
  end

  def to_h
    @store.dup
  end

  def to_hash
    @store.dup
  end

  def respond_to_missing?(method, include_private = false)
    @store.respond_to?(method) || super
  end

  def method_missing(method, *args, &block)
    if @store.respond_to?(method)
      @store.send(method, *args, &block)
    else
      super
    end
  end
end

# Lightweight struct that mimics the ActionDispatch::Request interface used
# inside the provider's process_webhook! and verify_webhook! methods.
# Only exposes what the providers actually read.
class WebhookRequestSnapshot
  def initialize(snapshot)
    @raw_headers = snapshot["headers"] || {}
    @body        = snapshot["body"].to_s
    @params      = snapshot["params"] || {}
  end

  # ActionDispatch::Request#headers interface (case-insensitive)
  def headers
    @headers ||= CaseInsensitiveHeadersHash.new(@raw_headers)
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
