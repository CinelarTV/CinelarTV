# frozen_string_literal: true

class UpdateCheckJob
  include Sidekiq::Job
  extend MiniScheduler::Schedule

  sidekiq_options queue: :default, retry: 1

  every 15.minutes

  def perform
    return unless SiteSetting.enable_web_updater

    CinelarTV::Updater.refresh_remote_version_cache
  end
end
