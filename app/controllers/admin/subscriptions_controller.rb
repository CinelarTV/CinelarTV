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

      render json: {
        data: paginated.as_json(include: { user: { only: %i[id email username] } }),
        meta: {
          page: page,
          per_page: per_page,
          total_count: subscriptions.count
        }
      }
    end

    def show
      subscription = UserSubscription.includes(:user).find(params[:id])
      render json: { data: subscription.as_json(include: { user: { only: %i[id email username] } }) }
    end

    def cancel
      subscription = UserSubscription.find(params[:id])
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
        status = remote["status"].to_s
        subscription.update(
          external_status: status.presence || subscription.external_status,
          metadata: subscription.metadata.merge("remote_sync" => remote)
        )
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

    def logs
      logs = WebhookLog.order(created_at: :desc).limit(200)
      render json: { data: logs.as_json }
    end

    private

    def provider_for(subscription)
      provider_key = subscription.provider.presence || SiteSetting.subscription_provider_primary
      Subscriptions::Providers::Registry.build(provider_key)
    end
  end
end
