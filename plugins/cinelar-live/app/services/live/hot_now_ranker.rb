# frozen_string_literal: true

module Live
  class HotNowRanker
    def self.rank(sessions)
      sessions.sort_by { |s| -calculate_score(s) }
    end

    def self.calculate_score(session)
      participant_score = (session.session_users.count || 0) * 10.0
      activity_score = calculate_activity(session)
      recency_score = calculate_recency(session)

      participant_score + activity_score + recency_score
    end

    private_class_method

    def self.calculate_activity(session)
      redis = Redis.current
      return 0 unless redis

      base = "live:activity:#{session.id}"
      joins = (redis.get("#{base}:joins") || 0).to_i
      messages = (redis.get("#{base}:messages") || 0).to_i

      (joins * 5) + (messages * 3)
    end

    def self.calculate_recency(session)
      return 0 unless session.last_activity_at

      seconds_ago = Time.current - session.last_activity_at
      [0, 100 - (seconds_ago / 60)].max
    end
  end
end
