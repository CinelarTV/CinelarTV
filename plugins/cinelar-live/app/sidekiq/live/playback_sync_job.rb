# frozen_string_literal: true

class Live::PlaybackSyncJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    Live::PlaybackSyncService.sync_all_active
  end
end
