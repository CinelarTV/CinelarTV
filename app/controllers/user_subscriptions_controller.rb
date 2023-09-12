# frozen_string_literal: true

class UserSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @subscriptions = UserSubscription.where(user_id: current_user.id)
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

  def subscription_params
    params.require(:user_subscription).permit(:plan_id)
  end
end
