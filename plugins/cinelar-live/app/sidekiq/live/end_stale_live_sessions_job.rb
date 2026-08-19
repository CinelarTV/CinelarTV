# frozen_string_literal: true

class Live::EndStaleLiveSessionsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    timeout = defined?(SiteSetting) ? SiteSetting.cinelar_live_activity_timeout : 600

    WatchParty::Session
      .where.not(live_event_id: nil)
      .where(ended_at: nil)
      .where("last_sync_at < ?", timeout.seconds.ago)
      .find_each do |session|
        session.update!(ended_at: Time.current, is_playing: false)
        session.live_event&.update!(status: :ended)

        if defined?(MessageBus)
          MessageBus.publish("/watchparty/#{session.id}", { type: "session_ended" })
          MessageBus.publish("/live/event/#{session.live_event_id}", { type: "event_ended" })
        end

        Live::ActivityTracker.reset(session.id)
        Rails.logger.info("[Live] Stale session #{session.id} ended")
      end
  end
end
