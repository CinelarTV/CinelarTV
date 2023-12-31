# frozen_string_literal: true

class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription

  def index
    @subscriptions = UserSubscription.where(user_id: current_user.id)

    subscription_data = get_subscription_details

    @subscriptions[:api_response] = subscription_data if subscription_data

    respond_to do |format|
      format.html
      format.json do
        render json: {
          data: @subscriptions.as_json

        }
      end
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
    data = nil
    if SiteSetting.lemon_api_key.blank?
      Rails.logger.error("LemonSqueezy API key is not set")
      return nil
    end

    # Fetch with headers
    response = HTTParty.get("https://api.lemonsqueezy.com/v1/subscriptions/#{@subscription.order_id}", headers: {
                              "Authorization" => "Bearer #{SiteSetting.lemon_api_key}"
                            })

    data = JSON.parse(response.body) if response.code == 200

    data
  rescue StandardError => e
    # Handle other exceptions
    Rails.logger.error("Error while getting subscription details for user #{current_user.id}: #{e.message}")
    nil
  end
end
