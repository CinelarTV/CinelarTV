# frozen_string_literal: true

class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider
  before_action :set_subscription

  def index
    link_preapproval_from_return_param!
    @subscriptions = UserSubscription.where(user_id: current_user.id)

    respond_to do |format|
      format.html
      format.json do
        enabled_providers = ::Subscriptions::Providers::Registry.enabled_provider_keys
        render json: {
          data: @subscriptions.as_json,
          provider: @provider.provider_key,
          enabled_providers: enabled_providers.map { |key| { key: key, label: provider_label(key) } }
        }
      end
    end
  end

  def subscribe
    checkout = @provider.create_subscription!(
      user: current_user,
      success_url: params[:success_url],
      failure_url: params[:failure_url],
      pending_url: params[:pending_url],
      checkout_mode: params[:checkout_mode],
      card_token_id: params[:card_token_id],
      start_date: params[:start_date],
      end_date: params[:end_date],
      amount: params[:amount],
      currency_id: params[:currency_id],
      frequency: params[:frequency],
      frequency_type: params[:frequency_type],
      repetitions: params[:repetitions],
      billing_day: params[:billing_day],
      billing_day_proportional: params[:billing_day_proportional]
    )

    persist_checkout_attempt!(checkout)
    persist_preapproval_link!(checkout[:preapproval_id])

    if !request.xhr? && request.format.html? && checkout[:checkout_url].present?
      redirect_to checkout[:checkout_url], allow_other_host: true
    else
      render json: { data: checkout }, status: :ok
    end
  rescue StandardError => e
    Rails.logger.error("Subscription creation failed for user #{current_user.id}: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def checkout
    subscribe
  end

  def destroy
    subscription = UserSubscription.find_by(user_id: current_user.id)
    return render json: { error: "Subscription not found" }, status: :not_found if subscription.blank?

    provider = ::Subscriptions::Providers::Registry.build(subscription.provider.presence || @provider.provider_key)
    provider.cancel_subscription!(subscription)

    subscription.destroy!
    render json: { message: "Subscription cancelled successfully", status: :ok }
  rescue StandardError => e
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

  def set_subscription
    @subscription = UserSubscription.find_by(user_id: current_user.id)
  end

  def subscription_params
    params.require(:user_subscription).permit(:plan_id)
  end

  def link_preapproval_from_return_param!
    preapproval_id = params[:preapproval_id].presence || params[:subscription_id].presence || params[:id].presence
    persist_preapproval_link!(preapproval_id)
  end

  def persist_preapproval_link!(preapproval_id)
    preapproval = preapproval_id.to_s
    return if preapproval.blank?

    subscription = UserSubscription.find_or_initialize_by(user_id: current_user.id)
    metadata = subscription.metadata || {}

    subscription.update!(
      provider: @provider.provider_key,
      provider_subscription_id: preapproval,
      checkout_reference: current_user.id,
      status: subscription.status.presence || "pending",
      status_formatted: subscription.status_formatted.presence || "Pending",
      metadata: metadata.merge(
        "preapproval_linked_from_billing" => true,
        "preapproval_linked_at" => Time.zone.now.iso8601
      )
    )
  end

  def persist_checkout_attempt!(checkout)
    subscription = UserSubscription.find_or_initialize_by(user_id: current_user.id)
    metadata = subscription.metadata || {}

    subscription.update!(
      provider: @provider.provider_key,
      checkout_reference: current_user.id,
      status: subscription.status.presence || "pending",
      status_formatted: subscription.status_formatted.presence || "Pending",
      provider_plan_id: checkout[:plan_id].presence || subscription.provider_plan_id,
      metadata: metadata.merge(
        "checkout_attempted" => true,
        "checkout_attempted_at" => Time.zone.now.iso8601,
        "checkout_fallback_reason" => checkout[:fallback_reason],
        "checkout_mode" => checkout[:checkout_mode]
      ).compact
    )
  end

  def provider_label(provider_key)
    labels = {
      "mercado_pago" => "Mercado Pago",
      "lemon_squeezy" => "Lemon Squeezy",
      "stripe" => "Stripe",
      "paypal" => "PayPal"
    }

    labels[provider_key.to_s] || provider_key.to_s.split("_").map(&:capitalize).join(" ")
  end
end
