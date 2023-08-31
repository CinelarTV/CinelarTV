# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController
    def index
      data = {}
      @problems = []
      unless !SiteSetting.license_key
        @problems << {
          content: "Your CinelarTV instance is not activated. Your customers will not be able to use the site until you activate it.",
          icon: "exclamation-triangle",
        }
      end

      data[:problems] = @problems

      respond_to do |format|
        format.html
        format.json do
          render json: data
        end
      end
    end

    def site_settings
      @settings = SiteSetting.all
      render json: { site_settings: @settings }
    end

    private

    def admin?
      render status: 404 unless current_user.has_role?(:admin)
    end
  end
end
