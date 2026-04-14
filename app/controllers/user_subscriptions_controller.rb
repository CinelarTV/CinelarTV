# frozen_string_literal: true

class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider
  before_action :set_subscription

  def index
    @subscriptions = UserSubscription.where(user_id: current_user.id)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          data: @subscriptions.as_json,
          provider: @provider.provider_key
        }
      end
    end
  end

  def checkout
    checkout = @provider.create_checkout!(
      user: current_user,
      success_url: params[:success_url],
      failure_url: params[:failure_url],
      pending_url: params[:pending_url]
    )

    render json: { data: checkout }, status: :ok
  rescue StandardError => e
    Rails.logger.error("Checkout creation failed for user #{current_user.id}: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @subscription = UserSubscription.find_by(id: params[:id])

    if @subscription.destroy
      render json: { message: "Subscription deleted successfully", status: :ok }
    else
      render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_provider
    @provider = Subscriptions::Providers::Registry.current
  end

  def set_subscription
    @subscription = UserSubscription.find_by(user_id: current_user.id)
  end

  def subscription_params
    params.require(:user_subscription).permit(:plan_id)
  end
end
