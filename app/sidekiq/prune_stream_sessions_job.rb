# frozen_string_literal: true

class PruneStreamSessionsJob
  include Sidekiq::Job
  extend MiniScheduler::Schedule

  sidekiq_options queue: :default, retry: 3

  every 1.hour

  def perform
    Rails.logger.info "Pruning stale stream session set members..."
    removed = StreamSessionManager.prune_stale_members
    Rails.logger.info "Pruned #{removed} stale stream session members."
  end
end
