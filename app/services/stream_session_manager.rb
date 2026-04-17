# frozen_string_literal: true

class StreamSessionManager
  Result = Struct.new(:success, :session_id, :active_sessions, :skipped, :error, keyword_init: true) do
    def success?
      success == true
    end

    def skipped?
      skipped == true
    end

    def limit_reached?
      !success? && active_sessions.present?
    end
  end

  class << self
    def start_session(user, device_name:, device_type:, profile_id: nil, requested_session_id: nil)
      return Result.new(success: true, skipped: true) unless SiteSetting.enable_stream_limit

      if requested_session_id.present?
        resumed = resume_session(user, requested_session_id, device_name: device_name, device_type: device_type, profile_id: profile_id)
        return resumed if resumed
      end

      session_id = SecureRandom.uuid
      now = Time.current.iso8601
      ttl = session_ttl_seconds
      grace = grace_ttl_seconds

      payload = redis.eval(
        session_create_script,
        [user_sessions_key(user.id), session_key(session_id)],
        [
          session_id,
          max_simultaneous_streams_per_user,
          ttl,
          grace,
          now,
          now,
          user.id.to_s,
          profile_id.to_s,
          device_name.to_s,
          device_type.to_s
        ]
      )

      parsed = JSON.parse(payload, symbolize_names: true)

      if parsed[:status] == "created"
        Result.new(success: true, session_id: session_id)
      else
        Result.new(success: false, active_sessions: parsed[:active_sessions] || [])
      end
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while starting session: #{e.message}")
      Result.new(success: true, skipped: true)
    end

    def resume_session(user, session_id, device_name:, device_type:, profile_id: nil)
      key = session_key(session_id)
      return nil unless redis.exists?(key)

      owner_id = redis.hget(key, "user_id")
      return nil unless owner_id.to_s == user.id.to_s

      now = Time.current.iso8601
      ttl = session_ttl_seconds

      redis.multi do |multi|
        multi.hset(key, "last_seen_at", now)
        multi.pexpire(key, ttl * 1000)
      end
      redis.sadd(user_sessions_key(user.id), session_id)

      Result.new(success: true, session_id: session_id)
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while resuming session #{session_id}: #{e.message}")
      nil
    end

    def ping_session(session_id)
      return if session_id.blank?

      key = session_key(session_id)
      return unless redis.exists?(key)

      now = Time.current.iso8601
      ttl = session_ttl_seconds

      redis.multi do |multi|
        multi.hset(key, "last_seen_at", now)
        multi.pexpire(key, ttl * 1000)
      end

      payload = redis.hgetall(key)
      payload["ttl"] = [redis.pttl(key), 0].max / 1000
      payload["session_id"] = session_id
      payload
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while pinging session #{session_id}: #{e.message}")
      nil
    end

    def end_session(session_id)
      return false if session_id.blank?

      key = session_key(session_id)
      user_id = redis.hget(key, "user_id")
      return false if user_id.blank?

      redis.del(key)
      redis.srem(user_sessions_key(user_id), session_id)
      true
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while ending session #{session_id}: #{e.message}")
      false
    end

    def kill_session(user, session_id)
      return false if session_id.blank?
      return :disabled unless SiteSetting.stream_force_kill_enabled

      key = session_key(session_id)
      owner_id = redis.hget(key, "user_id")
      return false if owner_id.blank?
      return :forbidden unless owner_id.to_s == user.id.to_s

      redis.del(key)
      redis.srem(user_sessions_key(user.id), session_id)
      true
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while killing session #{session_id}: #{e.message}")
      false
    end

    def list_sessions(user)
      return [] unless SiteSetting.enable_stream_limit

      session_ids = redis.smembers(user_sessions_key(user.id))
      sessions = []

      session_ids.each do |session_id|
        key = session_key(session_id)
        ttl = redis.pttl(key)

        if ttl <= 0
          redis.srem(user_sessions_key(user.id), session_id)
          next
        end

        meta = redis.hgetall(key)
        sessions << {
          session_id: session_id,
          user_id: meta["user_id"],
          profile_id: meta["profile_id"].presence,
          device_name: meta["device_name"],
          device_type: meta["device_type"],
          created_at: meta["created_at"],
          last_seen_at: meta["last_seen_at"],
          ttl: (ttl / 1000).to_i
        }
      end

      sessions.sort_by { |session| session[:last_seen_at].to_s }.reverse
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while listing sessions for user #{user.id}: #{e.message}")
      []
    end

    private

    def redis
      @redis ||= Cache.new.redis
    end

    def session_key(session_id)
      "stream:session:#{session_id}"
    end

    def user_sessions_key(user_id)
      "stream:user_sessions:#{user_id}"
    end

    def session_create_script
      <<~LUA
        local user_sessions_key = KEYS[1]
        local session_key = KEYS[2]
        local session_id = ARGV[1]
        local max_sessions = tonumber(ARGV[2])
        local ttl = tonumber(ARGV[3])
        local grace = tonumber(ARGV[4])
        local created_at = ARGV[5]
        local last_seen_at = ARGV[6]
        local user_id = ARGV[7]
        local profile_id = ARGV[8]
        local device_name = ARGV[9]
        local device_type = ARGV[10]

        local session_ids = redis.call("SMEMBERS", user_sessions_key)
        local active_sessions = {}
        local active_count = 0

        for i = 1, #session_ids do
          local sid = session_ids[i]
          local key = "stream:session:" .. sid
          local ttl_remain = redis.call("PTTL", key)

          if ttl_remain <= 0 then
            redis.call("SREM", user_sessions_key, sid)
          else
            if ttl_remain >= (grace * 1000) then
              active_count = active_count + 1
              local info = redis.call("HMGET", key, "device_name", "device_type", "last_seen_at")
              table.insert(active_sessions, {
                session_id = sid,
                device_name = info[1],
                device_type = info[2],
                last_seen_at = info[3],
                ttl = math.floor(ttl_remain / 1000)
              })
            end
          end
        end

        if active_count >= max_sessions then
          return cjson.encode({ status = "limit_reached", active_sessions = active_sessions })
        end

        redis.call("HMSET", session_key,
          "user_id", user_id,
          "profile_id", profile_id,
          "device_name", device_name,
          "device_type", device_type,
          "created_at", created_at,
          "last_seen_at", last_seen_at
        )
        redis.call("PEXPIRE", session_key, ttl * 1000)
        redis.call("SADD", user_sessions_key, session_id)

        return cjson.encode({ status = "created", session_id = session_id })
      LUA
    end

    def max_simultaneous_streams_per_user
      SiteSetting.max_simultaneous_streams_per_user.to_i.clamp(1, 10)
    end

    def session_ttl_seconds
      [
        SiteSetting.stream_session_timeout_seconds.to_i,
        SiteSetting.stream_ping_interval_seconds.to_i * 3
      ].max
    end

    def grace_ttl_seconds
      ttl = SiteSetting.stream_ping_interval_seconds.to_i - 1
      [[ttl, 1].max, 5].min
    end
  end
end
