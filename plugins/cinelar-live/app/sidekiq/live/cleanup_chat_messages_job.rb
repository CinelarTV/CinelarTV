# frozen_string_literal: true

class Live::CleanupChatMessagesJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  RETENTION_HOURS = 48

  def perform
    Live::ChatMessage
      .where("created_at < ?", RETENTION_HOURS.hours.ago)
      .in_batches(of: 1000)
      .delete_all
  end
end
