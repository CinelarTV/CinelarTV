# frozen_string_literal: true

class Live::CleanupChatMessagesJob
  include Sidekiq::Job
  extend MiniScheduler::Schedule

  sidekiq_options queue: :default, retry: 3

  every 1.hour

  RETENTION_HOURS = 48

  def perform
    Live::ChatMessage
      .where("created_at < ?", RETENTION_HOURS.hours.ago)
      .in_batches(of: 1000)
      .delete_all
  end
end
