# frozen_string_literal: true

class Admin::UpdatesController < Admin::BaseController
    def index
      respond_to do |format|
        format.html
        format.json do
          render json: updates_response
        end
      end
    end
  

    def run_update
      if !SiteSetting.enable_web_updater
        render json: {
          errors: [
            "Web updater disabled"
          ],
          error_type: "web_update_disabled"
        }, status: 403
      elsif !CinelarTV::Updater.updates_available?
        render json: {
          errors: [
            "No updates available"
          ],
          error_type: "no_updates_available"
        }
      else
        CinelarTV::Updater.run_update
        head :ok
      end
    end
  
    def check_progress
      progress, output = CinelarTV::Updater.run_update
      render json: { progress:, output: }
    end
  
    private
  
    def updates_response
      {
        versions_diff: CinelarTV::Updater.versions_diff,
        installed_sha: CinelarTV.git_version,
        remote_hash: CinelarTV::Updater.remote_version,
        updates_available: CinelarTV::Updater.updates_available?,
        last_commit_message: CinelarTV::Updater.last_commit_message
      }
    end
  end