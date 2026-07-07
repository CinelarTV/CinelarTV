# frozen_string_literal: true

module Oauth
  class DeviceAuthorizationsController < Doorkeeper::DeviceAuthorizationGrant::DeviceAuthorizationsController
    skip_before_action :verify_authenticity_token, if: -> { request.format.json? }

    def index
      respond_to do |format|
        format.html { render "application/index", layout: "application" }
        format.json { head :no_content }
      end
    end

    private

    def authorization_success_response
      respond_to do |format|
        notice = I18n.t(:success, scope: i18n_flash_scope(:authorize))
        format.html { redirect_to oauth_device_authorizations_index_url, notice: notice }
        format.json { render json: { message: notice }, status: :ok }
      end
    end
  end
end
