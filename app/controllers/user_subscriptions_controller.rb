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

  def subscribe
    checkout = @provider.create_subscription!(
      user: current_user,
      success_url: params[:success_url],
      failure_url: params[:failure_url],
      pending_url: params[:pending_url],
      card_token_id: params[:card_token_id],
      start_date: params[:start_date],
      end_date: params[:end_date],
      amount: params[:amount],
      currency_id: params[:currency_id],
      frequency: params[:frequency],
      frequency_type: params[:frequency_type],
      repetitions: params[:repetitions],
      billing_day: params[:billing_day],
      billing_day_proportional: params[:billing_day_proportational]
    )

    if !request.xhr? && request.format.html? && checkout[:checkout_url].present?
      # Store checkout info for polling when user returns
      session[:pending_checkout] = {
        provider: checkout[:provider],
        preapproval_id: checkout[:preapproval_id],
        plan_id: checkout[:plan_id],
        user_id: current_user.id,
        started_at: Time.zone.now
      }
      
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

  def return_from_checkout
    # Clear pending checkout
    pending = session.delete(:pending_checkout)
    
    # Queue a job to sync the subscription
    if pending.present?
      Subscriptions::SyncPendingCheckoutJob.perform_async(
        pending[:user_id],
        pending[:preapproval_id]
      )
    end
    
    redirect_to '/account/billing', notice: 'Processing your subscription. Please refresh in a moment.'
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
    @provider = ::Subscriptions::Providers::Registry.current
  end

  def set_subscription
    @subscription = UserSubscription.find_by(user_id: current_user.id)
  end

  def subscription_params
    params.require(:user_subscription).permit(:plan_id)
  end
end
