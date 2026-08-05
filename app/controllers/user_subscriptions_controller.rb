# frozen_string_literal: true

class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider

  def index
    @subscriptions = current_user.subscriptions.order(updated_at: :desc)
    @payments = current_user.payments.order(paid_at: :desc, created_at: :desc)

    ip_address = request.headers["CF-Connecting-IP"] || request.remote_ip
    ip_info = IpInfo.lookup(ip_address)
    country_code = ip_info[:country_code]

    respond_to do |format|
      format.html
      format.json do
        enabled_providers = ::Subscriptions::Providers::Registry.enabled_provider_keys
        render json: {
          data: @subscriptions.map { |subscription| subscription_payload(subscription) },
          payments: @payments.map { |payment| payment_payload(payment) },
          provider: @provider.provider_key,
          admin: current_user.is_admin?,
          enabled_providers: enabled_providers.map { |key| { key: key, label: provider_label(key) } },
          geo: {
            country_code: country_code,
            country_name: ip_info[:country],
            recommended_provider: recommend_provider(country_code)
          }
        }
      end
    end
  end

  def plan
    offering = Billing::Offering.current
    render json: {
      data: {
        id: offering.key,
        name: "CinelarTV",
        amount: offering.amount,
        currency: offering.currency,
        frequency: offering.interval_count,
        frequency_type: offering.interval_unit
      },
      provider: @provider.provider_key
    }
  end

  def subscribe
    lock_key = "billing_checkout_#{current_user.id}"
    result = nil
    current_user.with_advisory_lock(lock_key, timeout_seconds: 10) do
      subscription, checkout = Billing::StartCheckout.call(
        user: current_user, provider_key: @provider.provider_key,
        return_url: params[:success_url].presence || account_billing_url
      )

      if !request.xhr? && request.format.html? && checkout[:redirect_url].present?
        result = -> { redirect_to checkout[:redirect_url], allow_other_host: true }
      else
        result = { data: checkout.merge(subscription: subscription_payload(subscription), provider: @provider.provider_key) }
      end
    end

    case result
    when Hash
      render json: result, status: :ok
    when Proc
      result.call
    when nil
      # no-op: already handled inside the lock
    end
  rescue StandardError => e
    Rails.logger.error("Subscription creation failed for user #{current_user.id}: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def checkout
    subscribe
  end

  def destroy
    subscription = current_user.subscriptions.open.order(updated_at: :desc).first
    return render json: { error: "Subscription not found" }, status: :not_found if subscription.blank?

    provider = ::Subscriptions::Providers::Registry.build(subscription.provider_key)
    provider.cancel(subscription)
    Billing::SubscriptionTransition.apply!(subscription:, status: "cancelled")

    render json: {
      message: "Subscription cancelled successfully. You'll have access until #{subscription.access_until&.strftime('%B %d, %Y') || 'your current period ends'}",
      status: :ok
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def sync
    subscription = current_user.subscriptions.open.order(updated_at: :desc).first
    return render json: { error: "No subscription found" }, status: :not_found if subscription.blank?

    provider = ::Subscriptions::Providers::Registry.build(subscription.provider_key)

    remote = provider.fetch_remote_subscription(subscription)
    return render json: { error: "Could not fetch subscription from provider" }, status: :unprocessable_entity if remote.blank?

    Billing::RemoteSnapshot.apply!(subscription:, remote:)

    render json: {
      data: subscription_payload(subscription.reload),
      message: "Subscription synced successfully"
    }, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("Subscription sync: #{e.message}")
    render json: { error: "Subscription not found in provider" }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("Subscription sync failed: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_provider
    requested_provider = params[:provider].to_s.presence
    if requested_provider.present? && ::Subscriptions::Providers::Registry.enabled?(requested_provider)
      @provider = ::Subscriptions::Providers::Registry.build(requested_provider)
    else
      @provider = ::Subscriptions::Providers::Registry.current
    end
  end

  def provider_label(provider_key)
    ::Subscriptions::Providers::Registry.label_for(provider_key)
  end

  def subscription_payload(subscription)
    subscription.as_json.merge(
      "provider" => subscription.provider_key,
      "status_formatted" => subscription.status.humanize,
      "product_name" => "CinelarTV",
      "renews_at" => subscription.current_period_ends_at,
      "ends_at" => subscription.access_until,
      "cancelled" => subscription.status == "cancelled",
      "user_email" => current_user.email
    )
  end

  def payment_payload(payment)
    payment.as_json.merge(
      "provider" => payment.provider_key,
      "amount" => payment.amount_cents / 100.0
    )
  end

  MERCADOPAGO_COUNTRIES = %w[AR BR CL CO MX PE UY].freeze

  def recommend_provider(country_code)
    return "mercado_pago" if country_code.present? && MERCADOPAGO_COUNTRIES.include?(country_code)
    "lemon_squeezy"
  end
end
