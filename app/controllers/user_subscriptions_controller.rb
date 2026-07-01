# frozen_string_literal: true

class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider
  before_action :set_subscription

  def index
    link_preapproval_from_return_param!
    @subscriptions = UserSubscription.where(user_id: current_user.id)
    @payments = SubscriptionPayment.where(user_id: current_user.id).order(paid_at: :desc)

    ip_address = request.remote_ip
    ip_info = IpInfo.lookup(ip_address)
    country_code = ip_info[:country_code]

    respond_to do |format|
      format.html
      format.json do
        enabled_providers = ::Subscriptions::Providers::Registry.enabled_provider_keys
        render json: {
          data: @subscriptions.as_json,
          payments: @payments.as_json,
          provider: @provider.provider_key,
          admin: current_user.has_role?(:admin),
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
    provider_key = params[:provider].to_s.presence
    provider = if provider_key.present? && ::Subscriptions::Providers::Registry.enabled?(provider_key)
                 ::Subscriptions::Providers::Registry.build(provider_key)
               else
                 recommend = recommend_provider(
                   IpInfo.lookup(request.remote_ip)[:country_code]
                 )
                 ::Subscriptions::Providers::Registry.build(recommend)
               end

    plan_id = active_plan_id_for(provider.provider_key)
    if plan_id.blank?
      render json: { data: nil, provider: provider.provider_key }
      return
    end

    plans_response = provider.list_plans!(managed_only: false)
    plans = plans_response["results"] || plans_response["data"] || []
    selected = plans.find { |p| p["id"].to_s == plan_id.to_s }

    if selected.blank?
      render json: { data: nil, provider: provider.provider_key }
      return
    end

    recurring = selected["auto_recurring"] || {}
    render json: {
      data: {
        id: selected["id"],
        name: selected["reason"],
        amount: recurring["transaction_amount"],
        currency: recurring["currency_id"],
        frequency: recurring["frequency"],
        frequency_type: recurring["frequency_type"]
      },
      provider: provider.provider_key
    }
  rescue StandardError => e
    Rails.logger.error("Billing plan fetch failed: #{e.message}")
    render json: { data: nil, provider: provider_key, error: e.message }
  end

  def subscribe
    # Advisory lock per user+provider to prevent race conditions with webhooks
    # and duplicate subscription requests.
    lock_key = "subscription_#{current_user.id}_#{@provider.provider_key}_#{params[:product_id]}"
    result = nil

    UserSubscription.with_advisory_lock(lock_key, timeout_seconds: 10) do
      # For mobile app purchases, keep the provider token bound to the current
      # account and reject tokens already linked to another account in the provider.
      if @provider.provider_key == "google_play" && params[:product_id].present?
        existing = UserSubscription.where(
          user_id: current_user.id,
          provider: "google_play"
        ).where("metadata->>'product_id' = ? OR iap_product_id = ?", params[:product_id], params[:product_id])
         .first

        if existing.present?
          remote = @provider.verify_purchase(product_id: params[:product_id], purchase_token: params[:purchase_token])
          raise "Could not verify Google Play purchase" if remote.blank?

          normalized = @provider.normalize_remote_for_update(existing, remote)
          existing.update!(
            normalized.merge(
              purchase_token: params[:purchase_token],
              iap_product_id: params[:product_id],
              metadata: (normalized[:metadata] || existing.metadata).merge(
                "purchase_token" => params[:purchase_token],
                "product_id" => params[:product_id],
                "last_mobile_update" => Time.zone.now.iso8601
              )
            )
          )

          existing.reload
          result = { data: { message: "Subscription updated successfully", subscription: existing.as_json, provider: @provider.provider_key } }
          next # exits the advisory lock block
        end

        linked_purchase = UserSubscription.find_by(provider: "google_play", purchase_token: params[:purchase_token])
        if linked_purchase.present? && linked_purchase.user_id != current_user.id
          raise "This Google Play purchase is already linked to another account"
        end
      end

      checkout = @provider.create_subscription!(
        user: current_user,
        success_url: params[:success_url],
        failure_url: params[:failure_url],
        pending_url: params[:pending_url],
        checkout_mode: params[:checkout_mode],
        card_token_id: params[:card_token_id],
        purchase_token: params[:purchase_token],
        product_id: params[:product_id],
        package_name: params[:package_name],
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
        result = -> { redirect_to checkout[:checkout_url], allow_other_host: true }
      else
        checkout_response = checkout.merge(provider: @provider.provider_key)
        result = { data: checkout_response }
      end
    end

    # Render or redirect outside the advisory lock
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

  def purchase_status
    unless @provider.provider_key == "google_play"
      render json: { error: "Purchase status is only available for Google Play" }, status: :unprocessable_entity
      return
    end

    purchase_token = params[:purchase_token].to_s
    product_id = params[:product_id].to_s

    if purchase_token.blank? || product_id.blank?
      render json: { error: "purchase_token and product_id are required" }, status: :unprocessable_entity
      return
    end

    linked_purchase = UserSubscription.find_by(provider: "google_play", purchase_token: purchase_token)

    if linked_purchase.present? && linked_purchase.user_id != current_user.id
      render json: {
        data: {
          status: "owned_by_another_user",
          valid: false,
          message: "This Google Play purchase is already linked to another CinelarTV account"
        }
      }, status: :ok
      return
    end

    remote = @provider.verify_purchase(product_id: product_id, purchase_token: purchase_token)
    if remote.blank?
      render json: {
        data: {
          status: "invalid_or_expired",
          valid: false,
          message: "Google Play purchase could not be verified"
        }
      }, status: :ok
      return
    end

    subscription = linked_purchase || current_user.user_subscriptions.build(provider: "google_play")
    normalized = @provider.normalize_remote_for_update(subscription, remote)

    render json: {
      data: {
        status: linked_purchase.present? ? "owned_by_current_user" : "unlinked_valid_purchase",
        valid: true,
        subscription_status: normalized[:status],
        product_id: normalized[:iap_product_id] || product_id,
        ends_at: normalized[:ends_at],
        renews_at: normalized[:renews_at]
      }
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      data: {
        status: "invalid_or_expired",
        valid: false,
        message: "Google Play purchase was not found"
      }
    }, status: :ok
  rescue StandardError => e
    Rails.logger.error("Google Play purchase status failed for user #{current_user.id}: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    subscription = UserSubscription.find_by(user_id: current_user.id)
    return render json: { error: "Subscription not found" }, status: :not_found if subscription.blank?

    provider = ::Subscriptions::Providers::Registry.build(subscription.provider.presence || @provider.provider_key)
    provider.cancel_subscription!(subscription)

    # Don't delete - keep the record so user can see when their access ends
    render json: { 
      message: "Subscription cancelled successfully. You'll have access until #{subscription.ends_at&.strftime('%B %d, %Y') || 'your next billing date'}",
      status: :ok 
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def sync
    subscription = UserSubscription.find_by(user_id: current_user.id)
    return render json: { error: "No subscription found" }, status: :not_found if subscription.blank?

    provider = ::Subscriptions::Providers::Registry.build(subscription.provider.presence || @provider.provider_key)

    # Fetch fresh data from provider (returns raw provider Hash)
    remote = provider.fetch_subscription!(subscription)
    return render json: { error: "Could not fetch subscription from provider" }, status: :unprocessable_entity if remote.blank?

    # Normalize only the fields we know and trust — never dump the raw Hash
    # directly into the model to avoid accidental overwrites.
    normalized = provider.normalize_remote_for_update(subscription, remote)
    subscription.update!(normalized)

    render json: {
      data: subscription.reload.as_json,
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
    ::Subscriptions::Providers::Registry.label_for(provider_key)
  end

  def active_plan_id_for(provider_key)
    return SiteSetting.google_play_subscription_product_id.to_s.presence if provider_key.to_s == "google_play"

    method_name = "#{provider_key}_plan_id"
    return nil unless SiteSetting.respond_to?(method_name)

    SiteSetting.public_send(method_name).to_s.presence
  end

  MERCADOPAGO_COUNTRIES = %w[AR BR CL CO MX PE UY].freeze

  def recommend_provider(country_code)
    return "mercado_pago" if country_code.present? && MERCADOPAGO_COUNTRIES.include?(country_code)
    "lemon_squeezy"
  end
end
