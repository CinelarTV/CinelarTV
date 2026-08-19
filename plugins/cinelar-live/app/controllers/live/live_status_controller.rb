# frozen_string_literal: true

module Live
  class LiveStatusController < ApplicationController
    def active_sessions
      sessions = WatchParty::Session
        .where(is_public: true, ended_at: nil)
        .where.not(live_event_id: nil)
        .includes(:content, :session_users)

      ranked = Live::HotNowRanker.rank(sessions)

      render json: ranked.map { |session|
        {
          id: session.id,
          content: {
            id: session.content&.id,
            title: session.content&.title,
            poster: session.content&.cover
          },
          participant_count: session.session_users.count,
          playback_position: Live::PositionCalculator.current_position(session),
          is_playing: session.is_playing,
          last_activity_at: session.last_activity_at&.iso8601,
          activity_score: Live::HotNowRanker.calculate_score(session)
        }
      }
    end
  end
end
