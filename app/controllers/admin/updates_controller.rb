# frozen_string_literal: true

class Admin::UpdatesController < Admin::BaseController
  before_action :check_web_updater_enabled

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: updates_response
      end
    end
  end

  def run_update
    if !CinelarTV::Updater.updates_available?
      render json: {
               errors: [
                 "No updates available",
               ],
               error_type: "no_updates_available",
             }
    else
      CinelarTV::Updater.run_update
      head :ok
    end

    def restart_server
      CinelarTV::Updater.restart_server
      head :ok
    end
  end

  def check_progress
    progress, output = CinelarTV::Updater.run_update
    render json: { progress:, output: }
  end

  private

  def check_web_updater_enabled
    if !SiteSetting.enable_web_updater
      respond_to do |format|
        format.html do
          flash[:error] = I18n.t("admin.updates.web_updater_disabled")
          redirect_to '/admin'
        end
        format.json do
          render json: {
                   errors: [
                     I18n.t("admin.updates.web_updater_disabled"),
                   ],
                   error_type: "web_updater_disabled",
                 },
                 status: 403
        end
      end
    end
  end

  def updates_response
    {
      versions_diff: CinelarTV::Updater.versions_diff,
      installed_sha: CinelarTV.git_version,
      remote_hash: CinelarTV::Updater.remote_version,
      updates_available: CinelarTV::Updater.updates_available?,
      last_commit_message: CinelarTV::Updater.last_commit_message,
    }
  end
end
