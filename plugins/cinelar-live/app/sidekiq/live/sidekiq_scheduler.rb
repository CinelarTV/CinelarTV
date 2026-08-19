# frozen_string_literal: true

module Live
  class SidekiqScheduler
    def self.register
      Sidekiq.set_schedule("live_start_scheduled", {
        "every" => "1m",
        "class" => "Live::StartScheduledEventsJob",
        "queue" => "default"
      })

      Sidekiq.set_schedule("live_sync_playback", {
        "every" => "30s",
        "class" => "Live::PlaybackSyncJob",
        "queue" => "default"
      })

      Sidekiq.set_schedule("live_check_completion", {
        "every" => "2m",
        "class" => "Live::CheckEventCompletionJob",
        "queue" => "default"
      })

      Sidekiq.set_schedule("live_end_stale", {
        "every" => "5m",
        "class" => "Live::EndStaleLiveSessionsJob",
        "queue" => "default"
      })

      Sidekiq.set_schedule("live_cleanup_chat", {
        "every" => "1h",
        "class" => "Live::CleanupChatMessagesJob",
        "queue" => "default"
      })
    end
  end
end
