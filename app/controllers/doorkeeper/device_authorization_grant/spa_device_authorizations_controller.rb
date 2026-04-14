# frozen_string_literal: true

module Doorkeeper
  module DeviceAuthorizationGrant
    class SpaDeviceAuthorizationsController < Doorkeeper::ApplicationController
      layout "application"
      helper_method :current_user, :current_profile, :user_signed_in?

      before_action :authenticate_resource_owner!

      def index
        respond_to do |format|
          format.html { render template: "application/index", layout: "application" }
          format.json { head :no_content }
        end
      end

      def authorize
        device_grant_model.transaction do
          device_grant = device_grant_model.lock.find_by(user_code: normalized_user_code)
          return authorization_error_response(:invalid_user_code) if device_grant.nil?
          return authorization_error_response(:expired_user_code) if device_grant.expired?

          device_grant.update!(user_code: nil, resource_owner_id: current_resource_owner.id)
          authorization_success_response
        end
      end

      private

      # The main app layout expects these helpers from ApplicationController.
      def current_user
        current_resource_owner
      end

      def current_profile
        nil
      end

      def user_signed_in?
        current_user.present?
      end

      def authorization_success_response
        respond_to do |format|
          notice = I18n.t(:success, scope: i18n_flash_scope(:authorize))
          format.html { redirect_to oauth_device_authorizations_index_url, notice: notice }
          format.json { render json: { message: notice }, status: :ok }
        end
      end

      def authorization_error_response(error_message_key)
        respond_to do |format|
          notice = I18n.t(error_message_key, scope: i18n_flash_scope(:authorize))
          format.html { redirect_to oauth_device_authorizations_index_url, alert: notice }
          format.json { render json: { errors: [notice] }, status: :unprocessable_entity }
        end
      end

      def device_grant_model
        @device_grant_model ||= Doorkeeper::DeviceAuthorizationGrant.configuration.device_grant_model
      end

      def normalized_user_code
        params[:user_code].to_s.strip.upcase
      end

      def i18n_flash_scope(action)
        %I[doorkeeper flash device_codes authorize]
      end
    end
  end
end
