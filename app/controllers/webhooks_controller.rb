# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:callback]
  before_action :verify_signature, only: [:callback]

  def callback
    event_name = request.headers["X-Event-Name"]
    payload = JSON.parse(request.body.read)

    WebhookLog.create!(event_name: event_name, payload: payload.to_json) unless event_name == "license_key_updated"

    case event_name
    when "subscription_created"
      handle_subscription_created(payload)
    when "subscription_updated"
      handle_subscription_updated(payload)
    else
      render plain: "Invalid event", status: :unprocessable_entity
    end
  end

  private

  def verify_signature
    secret = SiteSetting.lemon_webhook_secret || ""
    payload = request.raw_post
    header_signature = request.headers["X-Signature"]

    if secret.blank? || payload.blank? || header_signature.blank?
      render plain: "Invalid signature", status: :unauthorized
      return
    end

    # Calcula la firma localmente utilizando la clave secreta
    local_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)

    # Compara la firma calculada con la firma proporcionada en el encabezado
    unless ActiveSupport::SecurityUtils.secure_compare(local_signature, header_signature)
      render plain: "Invalid signature", status: :unauthorized
    end
  end

  def handle_subscription_created(payload)
    subscription_data = payload["data"]["attributes"]
    customer_id = subscription_data["customer_id"]

    user = User.find_by(customer_id: customer_id) || User.find_by(email: subscription_data["user_email"])

    if user.nil?
      user = User.create!(
        customer_id: customer_id,
        email: subscription_data["user_email"],
        username: subscription_data["user_name"].gsub(" ", "_"),
      )
    else
      user.update(customer_id: customer_id)
    end

    create_user_subscription(user, subscription_data)
  end

  def handle_subscription_updated(payload)
    order_id = payload["data"]["attributes"]["order_id"]
    user_subscription = UserSubscription.find_by(order_id: order_id)

    if user_subscription
      update_user_subscription(user_subscription, payload["data"]["attributes"])
    end
  end

  def create_user_subscription(user, subscription_data)
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
  end

  def update_user_subscription(user_subscription, attributes)
    user_subscription.update(
      status: attributes["status"],
      status_formatted: attributes["status_formatted"],
      card_brand: attributes["card_brand"],
      card_last_four: attributes["card_last_four"],
      cancelled: attributes["cancelled"],
      trial_ends_at: attributes["trial_ends_at"],
      billing_anchor: attributes["billing_anchor"],
      renews_at: attributes["renews_at"],
      ends_at: attributes["ends_at"],
      updated_at: attributes["updated_at"],
      test_mode: attributes["test_mode"],
    )
  end
end
