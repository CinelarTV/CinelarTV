# frozen_string_literal: true

module Live
  class PlaybackSyncService
    def self.sync_all_active
      WatchParty::Session
        .where.not(live_event_id: nil)
        .where(ended_at: nil)
        .find_each { |session| sync_session(session) }
    end

    def self.sync_session(session)
      position = PositionCalculator.current_position(session)

      session.update!(
        playback_position: position,
        playback_current_time: position,
        last_playback_update_at: Time.current
      )

      if defined?(MessageBus)
        MessageBus.publish("/watchparty/#{session.id}", {
          type: "playback_sync",
          current_time: position,
          is_playing: true,
          source: "system"
        })
      end
    end
  end
end
