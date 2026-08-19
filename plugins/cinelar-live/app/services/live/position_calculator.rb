# frozen_string_literal: true

module Live
  class PositionCalculator
    def self.current_position(session)
      return 0 unless session.started_at

      if session.is_playing
        last_update = session.last_playback_update_at || session.started_at
        elapsed = Time.current - last_update
        session.playback_position + elapsed.to_f
      else
        session.playback_position
      end
    end
  end
end
