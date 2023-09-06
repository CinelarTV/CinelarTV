# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController
    include Admin::DashboardHelper

    def index
      data = {}
      @problems = []
      if !SiteSetting.license_key.present?
        @problems << {
          content: "Your CinelarTV instance is not activated. Your customers will not be able to use the site until you activate it.",
          type: "critical",
          icon: "key",
        }

        if !SiteSetting.wizard_completed
          @problems << {
            content: "Looks like you haven't completed the setup wizard yet. You can complete it by going to the <a href='/wizard'>setup wizard</a>.",
            type: "warning",
            icon: "magic",
          }
        end
      end

      data[:problems] = @problems
      data[:version_check] = {
        installed_version: CinelarTV::Application::Version::FULL,
        installed_sha: CinelarTV.git_version,
        git_branch: CinelarTV.git_branch,
        last_commit_date: CinelarTV.last_commit_date,
        updates_available: CinelarTV::Updater.updates_available?,
        remote_version: CinelarTV::Updater.remote_version,
        versions_diff: CinelarTV::Updater.versions_diff,
        last_commit_message: CinelarTV::Updater.last_commit_message,
      }

      data[:statistics] = statistics

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
