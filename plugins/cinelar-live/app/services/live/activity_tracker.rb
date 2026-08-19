# frozen_string_literal: true

module Live
  class ActivityTracker
    WINDOW = 300

    def self.track_join(session_id)
      redis = Redis.current
      return unless redis

      key = "live:activity:#{session_id}:joins"
      redis.incr(key)
      redis.expire(key, WINDOW)
      update_last_activity(session_id)
    end

    def self.track_message(session_id)
      redis = Redis.current
      return unless redis

      key = "live:activity:#{session_id}:messages"
      redis.incr(key)
      redis.expire(key, WINDOW)
      update_last_activity(session_id)
    end

    def self.reset(session_id)
      redis = Redis.current
      return unless redis

      redis.del(
        "live:activity:#{session_id}:joins",
        "live:activity:#{session_id}:messages"
      )
    end

    private_class_method

    def self.update_last_activity(session_id)
      WatchParty::Session.where(id: session_id).update_all(last_activity_at: Time.current)
    end
  end
end
