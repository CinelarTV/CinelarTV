# frozen_string_literal: true

require "sidekiq-scheduler"

class UpdateCheckJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 1

  def perform
    return unless SiteSetting.enable_web_updater

    CinelarTV::Updater.refresh_remote_version_cache
  end
end
