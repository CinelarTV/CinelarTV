# frozen_string_literal: true

class WebhooksController < ApplicationController
  before_action :verify_signature, only: [:callback]

  def callback
    event_name = request.headers["X-Event-Name"]
    payload = JSON.parse(request.body.read)

    WebhookLog.create!(event_name: event_name, payload: payload.to_json)

    case event_name
    when "subscription_created"
      subscription_data = payload["data"]["attributes"]
      customer_id = subscription_data["customer_id"]

      user = User.find_by(customer_id: customer_id)

      if user.nil?
        # Buscar el usuario por correo electrónico
        user = User.find_by(email: subscription_data["user_email"])

        if user.nil?
          # Si el usuario no existe, crea uno nuevo
          user = User.create!(
            customer_id: customer_id,
            email: subscription_data["user_email"],
            username: subscription_data["user_name"].gsub(" ", "_"),
          )
        else
          # Si el usuario existe, actualiza el customer_id
          user.update(customer_id: customer_id)
        end
      end

      # Ahora crea la suscripción
      UserSubscription.create!(
        user_id: user.id,
        order_id: subscription_data["order_id"],
        order_item_id: subscription_data["order_item_id"],
        product_id: subscription_data["product_id"],
        variant_id: subscription_data["variant_id"],
        product_name: subscription_data["product_name"],
        variant_name: subscription_data["variant_name"],
        user_name: subscription_data["user_name"],
        user_email: subscription_data["user_email"],
        status: subscription_data["status"],
        status_formatted: subscription_data["status_formatted"],
        card_brand: subscription_data["card_brand"],
        card_last_four: subscription_data["card_last_four"],
        cancelled: subscription_data["cancelled"],
        trial_ends_at: subscription_data["trial_ends_at"],
        billing_anchor: subscription_data["billing_anchor"],
        renews_at: subscription_data["renews_at"],
        ends_at: subscription_data["ends_at"],
        created_at: subscription_data["created_at"],
        updated_at: subscription_data["updated_at"],
        test_mode: subscription_data["test_mode"],
      )
    when "subscription_updated"
      # Handle subscription updated event

      UserSubscription.find_by(order_id: payload["data"]["attributes"]["order_id"]).update(
        status: payload["data"]["attributes"]["status"],
        status_formatted: payload["data"]["attributes"]["status_formatted"],
        card_brand: payload["data"]["attributes"]["card_brand"],
        card_last_four: payload["data"]["attributes"]["card_last_four"],
        cancelled: payload["data"]["attributes"]["cancelled"],
        trial_ends_at: payload["data"]["attributes"]["trial_ends_at"],
        billing_anchor: payload["data"]["attributes"]["billing_anchor"],
        renews_at: payload["data"]["attributes"]["renews_at"],
        ends_at: payload["data"]["attributes"]["ends_at"],
        updated_at: payload["data"]["attributes"]["updated_at"],
        test_mode: payload["data"]["attributes"]["test_mode"],
      )
    else
      render plain: "Invalid event", status: :unprocessable_entity
    end

    render plain: "OK", status: :ok
  end

  private

  def verify_signature
    secret = SiteSetting.lemon_webhook_secret || ""
    payload = request.raw_post
    header_signature = request.headers["X-Signature"]

    if secret.blank? || payload.blank? || header_signature.blank?
      render plain: "Invalid signature", status: :unauthorized
    end

    # Calcula la firma localmente utilizando la clave secreta
    local_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)

    # Compara la firma calculada con la firma proporcionada en el encabezado
    unless ActiveSupport::SecurityUtils.secure_compare(local_signature, header_signature)
      render plain: "Invalid signature", status: :unauthorized
    end
  end
end
