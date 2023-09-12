# frozen_string_literal: true

class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription

  def index
    @subscriptions = UserSubscription.where(user_id: current_user.id)

    subscription_data = get_subscription_details

    if subscription_data
      @subscriptions[:api_response] = subscription_data
    end

    respond_to do |format|
      format.html
      format.json {
        render json: {
                 data: @subscriptions.as_json,

               }
      }
    end
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

  def set_subscription
    @subscription = UserSubscription.find_by(user_id: current_user.id)
  end

  def subscription_params
    params.require(:user_subscription).permit(:plan_id)
  end

  def get_subscription_details
    response = HTTParty.get("https://api.lemonsqueezy.com/v1/subscriptions/#{@subscription.order_id}")
    # https://api.lemonsqueezy.com/v1/subscriptions/id

    if response.code == 200
      data = JSON.parse(response.body)
      data
    end
  rescue StandardError => e
    # Handle other exceptions
    Rails.logger.error("Error while getting subscription details for user #{current_user.id}: #{e.message}")
    return nil
  end
end
