# frozen_string_literal: true

module Subscriptions
  module Providers
    class Registry
      PROVIDERS = {
        "mercado_pago" => "Subscriptions::Providers::MercadoPagoProvider",
        "lemon_squeezy" => "Subscriptions::Providers::LemonSqueezyProvider",
        "google_play" => "Subscriptions::Providers::GooglePlayProvider",
        "manual" => "Subscriptions::Providers::ManualProvider"
      }.freeze

      PROVIDER_FEATURE_FLAGS = {
        "mercado_pago" => :enable_mercado_pago_provider,
        "lemon_squeezy" => :enable_lemon_squeezy_provider,
        "google_play" => :enable_google_play_provider
      }.freeze

      PROVIDER_LABELS = {
        "mercado_pago"  => "Mercado Pago",
        "lemon_squeezy" => "Lemon Squeezy",
        "stripe"        => "Stripe",
        "paypal"        => "PayPal",
        "google_play"   => "Google Play",
        "manual"        => "Manual"
      }.freeze

      class << self
        def current
          enabled = enabled_provider_keys
          key = enabled.first.presence || SiteSetting.subscription_provider_primary.presence || "mercado_pago"
          build(key)
        end

        def build(key)
          provider_class_name = PROVIDERS[key.to_s]
          raise ArgumentError, "Unknown subscription provider: #{key}" if provider_class_name.blank?

          provider_class_name.constantize.new
        end

        def enabled?(key)
          enabled_provider_keys.include?(key.to_s)
        end

        def enabled_providers
          enabled_provider_keys.map { |key| build(key) }
        end

        def enabled_provider_keys
          keys = PROVIDER_FEATURE_FLAGS.select do |_key, flag|
            SiteSetting.respond_to?(flag) && SiteSetting.public_send(flag)
          end.keys

          return keys if keys.any?

          # Backward compatibility: fall back to subscription_provider_primary
          primary = SiteSetting.subscription_provider_primary.to_s.presence
          primary && PROVIDERS.key?(primary) ? [primary] : ["mercado_pago"]
        end

        # Returns a human-readable label for a provider key.
        # Single source of truth — use this in controllers and helpers instead of
        # duplicating the labels hash.
        def label_for(provider_key)
          key = provider_key.to_s.strip.downcase
          PROVIDER_LABELS[key] || key.split("_").map(&:capitalize).join(" ")
        end
      end
    end
  end
end
