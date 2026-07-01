# frozen_string_literal: true

module Admin
  class SubscriptionsController < Admin::BaseController
    def index
      subscriptions = UserSubscription.includes(:user).order(updated_at: :desc)
      subscriptions = subscriptions.where(provider: params[:provider]) if params[:provider].present?
      subscriptions = subscriptions.where(status: params[:status]) if params[:status].present?

      if params[:query].present?
        q = "%#{params[:query].downcase}%"
        subscriptions = subscriptions.joins(:user).where(
          "LOWER(users.email) LIKE ? OR LOWER(users.username) LIKE ? OR CAST(user_subscriptions.id AS TEXT) LIKE ?",
          q,
          q,
          q
        )
      end

      page = params[:page].to_i.positive? ? params[:page].to_i : 1
      per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 30

      paginated = subscriptions.offset((page - 1) * per_page).limit(per_page)

      respond_to do |format|
        format.html { render "application/index" }
        format.json do
          render json: {
            data: paginated.as_json(include: { user: { only: %i[id email username] } }),
            meta: {
              page: page,
              per_page: per_page,
              total_count: subscriptions.count,
              available_providers: available_provider_options,
              current_provider: current_provider.provider_key
            }
          }
        end
      end
    end

    def show
      subscription = UserSubscription.includes(:user).find(params[:id])
      render json: { data: subscription.as_json(include: { user: { only: %i[id email username] } }) }
    end

    def create_grant
      user = User.find(params[:user_id])
      duration_days = params[:days].to_i.positive? ? params[:days].to_i : 30

      if user.user_subscriptions.active.exists?
        render json: { error: "El usuario ya tiene una suscripción activa" }, status: :unprocessable_entity
        return
      end

      subscription = Subscriptions::Providers::ManualProvider.new.create_subscription!(
        user: user,
        days: duration_days
      )

      render json: { data: subscription.reload.as_json(include: { user: { only: %i[id email username] } }) }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def cancel
      subscription = UserSubscription.find(params[:id])

      if subscription.provider == "manual"
        subscription.update!(
          cancelled: true,
          cancelled_at: Time.zone.now,
          status: "cancelled",
          status_formatted: "Cancelled",
          external_status: "cancelled_by_admin"
        )
        render json: { data: subscription.reload.as_json }
        return
      end

      provider = provider_for(subscription)

      provider.cancel_subscription!(subscription)
      render json: { data: subscription.reload.as_json }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def sync
      subscription = UserSubscription.find(params[:id])
      provider = provider_for(subscription)
      remote = provider.fetch_subscription!(subscription)

      if remote.is_a?(Hash)
        # Use provider normalization for consistent status handling
        normalized_data = provider.normalize_remote_for_update(subscription, remote)
        subscription.update(normalized_data)
      end

      render json: { data: subscription.reload.as_json, remote: remote }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def grant
      subscription = UserSubscription.find(params[:id])
      duration_days = params[:days].to_i.positive? ? params[:days].to_i : 30

      subscription.update!(
        status: "active",
        status_formatted: "Active",
        cancelled: false,
        granted_by_admin: true,
        granted_until: duration_days.days.from_now,
        renews_at: duration_days.days.from_now,
        ends_at: nil,
        external_status: "granted_by_admin"
      )

      render json: { data: subscription.reload.as_json }
    end

    def stats
      this_month_start = Time.zone.now.beginning_of_month
      this_month_end = Time.zone.now.end_of_month
      month_payments = SubscriptionPayment.where(paid_at: this_month_start..this_month_end)

      render json: {
        total:     UserSubscription.count,
        active:    UserSubscription.active.count,
        pending:   UserSubscription.where(status: "pending").count,
        cancelled: UserSubscription.where(status: %w[cancelled canceled]).count,
        granted:   UserSubscription.where(granted_by_admin: true).count,
        revenue_this_month: month_payments.sum(:amount).to_f,
        payments_count_this_month: month_payments.count,
        currency: SiteSetting.respond_to?(:subscription_currency) ? SiteSetting.subscription_currency : "UYU"
      }
    end

    def logs
      logs = WebhookLog.order(created_at: :desc).limit(200)
      render json: { data: logs.as_json }
    end

    def test_webhook
      # Fetch the most recent subscription to test with
      subscription = UserSubscription.order(updated_at: :desc).first
      
      if subscription.blank?
        render json: { error: 'No subscriptions found to test with' }, status: :unprocessable_entity
        return
      end

      provider = provider_for(subscription)
      
      begin
        # Fetch the subscription from provider
        remote = provider.fetch_subscription!(subscription)
        
        if remote.is_a?(Hash)
          # Use provider normalization for consistent status handling
          normalized_data = provider.normalize_remote_for_update(subscription, remote)
          # Add test-specific metadata
          normalized_data[:metadata] = normalized_data[:metadata].merge("last_test_sync" => Time.zone.now.iso8601, "remote_data" => remote)
          subscription.update(normalized_data)
          
          render json: {
            message: 'Webhook test successful',
            data: subscription.as_json,
            remote_data: remote
          }
        else
          render json: { error: 'Invalid response from provider' }, status: :unprocessable_entity
        end
      rescue StandardError => e
        render json: { error: "Webhook test failed: #{e.message}" }, status: :unprocessable_entity
      end
    end

    def plans
      provider = provider_from_params
      managed_only = ActiveModel::Type::Boolean.new.cast(params.fetch(:managed_only, true))
      plans_response = provider.list_plans!(managed_only: managed_only)
      plans = plans_response["results"] || plans_response["data"] || []

      render json: {
        data: plans,
        meta: {
          active_plan_id: active_plan_id_for(provider.provider_key),
          provider: provider.provider_key,
          provider_label: provider_label(provider.provider_key)
        }
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def select_plan
      plan_id = params[:plan_id].to_s
      raise ArgumentError, "Plan id is required" if plan_id.blank?

      provider = provider_from_params
      set_active_plan_id_for(provider.provider_key, plan_id)

      render json: {
        data: {
          active_plan_id: active_plan_id_for(provider.provider_key),
          provider: provider.provider_key,
          message: "Plan selected for CinelarTV"
        }
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def create_plan
      provider = provider_from_params
      plan = provider.create_plan!(plan_params)

      render json: { data: plan }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_plan
      provider = provider_from_params
      plan = provider.update_plan!(params[:plan_id], plan_params)

      render json: { data: plan }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def deactivate_plan
      provider = provider_from_params
      plan = provider.deactivate_plan!(params[:plan_id])

      render json: { data: plan }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def provider_for(subscription)
      provider_key = subscription.provider.presence || SiteSetting.subscription_provider_primary
      ::Subscriptions::Providers::Registry.build(provider_key)
    end

    def current_provider
      ::Subscriptions::Providers::Registry.current
    end

    def provider_from_params
      requested = params[:provider].to_s.presence
      if requested.present? && ::Subscriptions::Providers::Registry.enabled?(requested)
        ::Subscriptions::Providers::Registry.build(requested)
      else
        current_provider
      end
    end

    def plan_params
      params.permit(:reason, :currency_id, :amount, :frequency, :frequency_type, :status, :back_url)
    end

    def available_provider_options
      # Get all enabled providers from Registry
      provider_keys = ::Subscriptions::Providers::Registry.enabled_provider_keys
      
      # Also include providers that have existing subscriptions (for historical data)
      provider_keys += UserSubscription.distinct.pluck(:provider).compact

      # Always include "manual" (house subscriptions created by admins)
      provider_keys << "manual"

      provider_keys
        .uniq
        .sort
        .map do |provider_key|
          {
            key: provider_key,
            label: provider_label(provider_key)
          }
        end
    end

    def provider_label(provider_key)
      ::Subscriptions::Providers::Registry.label_for(provider_key)
    end

    def active_plan_setting_method_for(provider_key)
      return "google_play_subscription_product_id" if provider_key.to_s == "google_play"

      "#{provider_key}_plan_id"
    end

    def active_plan_id_for(provider_key)
      method_name = active_plan_setting_method_for(provider_key)

      if SiteSetting.respond_to?(method_name)
        SiteSetting.public_send(method_name).to_s
      else
        nil
      end
    end

    def set_active_plan_id_for(provider_key, plan_id)
      method_name = "#{active_plan_setting_method_for(provider_key)}="

      if SiteSetting.respond_to?(method_name)
        SiteSetting.public_send(method_name, plan_id)
      else
        # Do nothing if the provider doesn't have a dedicated setting
        Rails.logger.warn "No plan setting method found for provider: #{provider_key}"
      end
    end

  end
end
