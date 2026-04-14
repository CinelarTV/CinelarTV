# frozen_string_literal: true

module Subscriptions
  module Providers
    class Registry
      PROVIDERS = {
        "mercado_pago" => "Subscriptions::Providers::MercadoPagoProvider"
      }.freeze

      class << self
        def current
          key = SiteSetting.subscription_provider_primary.presence || "mercado_pago"
          build(key)
        end

        def build(key)
          provider_class_name = PROVIDERS[key.to_s]
          raise ArgumentError, "Unknown subscription provider: #{key}" if provider_class_name.blank?

          provider_class_name.constantize.new
        end
      end
    end
  end
end
