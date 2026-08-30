# frozen_string_literal: true

class Live::PlaybackSyncJob
  include Sidekiq::Job
  extend MiniScheduler::Schedule

  sidekiq_options queue: :default, retry: 3

  every 30.seconds

  def perform
    Live::PlaybackSyncService.sync_all_active
  end
end
