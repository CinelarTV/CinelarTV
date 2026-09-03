# frozen_string_literal: true

module Admin
  class SubscriptionsController < Admin::BaseController
    def index
      scope = Subscription.includes(:user).order(updated_at: :desc)
      scope = scope.where(provider_key: params[:provider]) if params[:provider].present?
      scope = scope.where(status: params[:status]) if params[:status].present?
      if params[:query].present?
        query = "%#{params[:query].downcase}%"
        scope = scope.joins(:user).where("LOWER(users.email) LIKE ? OR LOWER(users.username) LIKE ? OR CAST(subscriptions.id AS TEXT) LIKE ?", query, query, query)
      end

      page = params[:page].to_i.positive? ? params[:page].to_i : 1
      per_page = [[params[:per_page].to_i, 1].max, 100].min
      per_page = 30 if params[:per_page].blank?
      records = scope.offset((page - 1) * per_page).limit(per_page)
      render json: { data: records.map { |record| subscription_payload(record) }, meta: metadata(scope, page, per_page) }
    end

    def show
      render json: { data: subscription_payload(Subscription.includes(:user).find(params[:id])) }
    end

    def cancel
      subscription = Subscription.find(params[:id])
      provider_for(subscription).cancel(subscription)
      Billing::SubscriptionTransition.apply!(subscription:, status: "cancelled")
      render json: { data: subscription_payload(subscription.reload) }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def sync
      subscription = Subscription.find(params[:id])
      remote = provider_for(subscription).fetch_remote_subscription(subscription)
      return render json: { error: "Provider did not return a subscription" }, status: :unprocessable_entity if remote.blank?

      Billing::RemoteSnapshot.apply!(subscription:, remote:)
      render json: { data: subscription_payload(subscription.reload), remote: remote }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def create_grant
      user = User.find(params[:user_id])
      days = params[:days].to_i.positive? ? params[:days].to_i : 30
      grant = user.subscription_access_grants.create!(starts_at: Time.current, ends_at: days.days.from_now, reason: params[:reason].presence || "Admin grant", granted_by_user: current_user)
      render json: { data: grant.as_json(include: { user: { only: %i[id email username] } }) }
    end

    def grant
      subscription = Subscription.find(params[:id])
      days = params[:days].to_i.positive? ? params[:days].to_i : 30
      grant = subscription.user.subscription_access_grants.create!(starts_at: Time.current, ends_at: days.days.from_now, reason: params[:reason].presence || "Admin grant", granted_by_user: current_user)
      render json: { data: grant.as_json }
    end

    def stats
      payments = Payment.where(status: "succeeded", paid_at: Time.current.beginning_of_month..Time.current.end_of_month)
      render json: {
        total: Subscription.count, active: Subscription.where(status: "active").count,
        pending: Subscription.where(status: "pending").count,
        cancelled: Subscription.where(status: %w[cancelled expired]).count,
        granted: SubscriptionAccessGrant.active_at.count,
        revenue_this_month: payments.sum(:amount_cents) / 100.0,
        payments_count_this_month: payments.count, currency: Billing::Offering.current.currency
      }
    end

    def logs
      events = ProviderEvent.order(received_at: :desc).limit(200).map do |event|
        event.as_json.merge(
          "event_name" => "#{event.provider_key}:#{event.event_type}",
          "status" => event.processing_error.present? ? 500 : (event.processed_at.present? ? 200 : 202)
        )
      end
      render json: { data: events }
    end

    def test_webhook
      subscription = Subscription.order(updated_at: :desc).first
      return render json: { error: "No subscriptions found" }, status: :unprocessable_entity unless subscription
      remote = provider_for(subscription).fetch_remote_subscription(subscription)
      return render json: { error: "Provider did not return a subscription" }, status: :unprocessable_entity if remote.blank?

      Billing::RemoteSnapshot.apply!(subscription:, remote:)
      render json: { message: "Reconciliation successful", data: subscription_payload(subscription.reload), remote_data: remote }
    end

    private

    def metadata(scope, page, per_page)
      { page:, per_page:, total_count: scope.count, available_providers: available_provider_options, current_provider: current_provider.provider_key }
    end

    def subscription_payload(subscription)
      subscription.as_json(include: { user: { only: %i[id email username] } }).merge(
        "provider" => subscription.provider_key,
        "status_formatted" => subscription.status.humanize,
        "product_name" => "CinelarTV",
        "renews_at" => subscription.current_period_ends_at,
        "ends_at" => subscription.access_until,
        "cancelled" => subscription.status == "cancelled"
      )
    end

    def provider_for(subscription)
      ::Subscriptions::Providers::Registry.build(subscription.provider_key)
    end

    def current_provider
      ::Subscriptions::Providers::Registry.current
    end

    def available_provider_options
      (Subscriptions::Providers::Registry.enabled_provider_keys + Subscription.distinct.pluck(:provider_key)).uniq.sort.map do |key|
        { key: key, label: Subscriptions::Providers::Registry.label_for(key) }
      end
    end
  end
end
