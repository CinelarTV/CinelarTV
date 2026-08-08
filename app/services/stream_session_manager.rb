# frozen_string_literal: true

# Manages active PlaybackSessions in Redis.
#
# Concurrency model (single Redis node):
#   * The stream limit is enforced per ACCOUNT: membership lives in
#     `stream:user_sessions:<user_id>` and the count+reserve is done inside a
#     single atomic Lua script (`session_create_script`).
#   * `profile_id` is METADATA of each PlaybackSession (stored in the session
#     hash) so the account can identify which profile/device is streaming. It
#     is NOT part of the counting/reservation mechanism.
#
# Key layout:
#   stream:user_sessions:<user_id>        -> SET of session ids (per account)
#   stream:session:<session_id>           -> HASH (user_id, profile_id, device_name,
#                                            device_type, created_at, last_seen_at,
#                                            content_title, episode_title) + TTL
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
    def start_session(user, device_name:, device_type:, profile_id: nil, requested_session_id: nil, client_request_id: nil, content_title: nil, episode_title: nil)
      return Result.new(success: true, skipped: true) unless SiteSetting.enable_stream_limit

      if requested_session_id.present?
        resumed = resume_session(user, requested_session_id, device_name: device_name, device_type: device_type, profile_id: profile_id, content_title: content_title, episode_title: episode_title)
        return resumed if resumed
      end

      session_id = SecureRandom.uuid
      now = Time.current.iso8601
      ttl = session_ttl_seconds
      grace = grace_ttl_seconds

      payload = redis.eval(
        session_create_script,
        [user_sessions_key(user.id), session_key(session_id), client_request_key(user.id, client_request_id)],
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
          device_type.to_s,
          content_title.to_s,
          episode_title.to_s,
          client_request_id.to_s
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

    # Re-acquires a still-alive session for the same user. Runs in a single Lua
    # script to avoid a race between the existence check and the renewal. When
    # a profile_id is supplied it is refreshed in the hash so the session keeps
    # pointing at the profile currently using it.
    def resume_session(user, session_id, device_name:, device_type:, profile_id: nil, content_title: nil, episode_title: nil)
      key = session_key(session_id)
      now = Time.current.iso8601
      ttl = session_ttl_seconds

      result = redis.eval(
        resume_script,
        [key, user_sessions_key(user.id)],
        [user.id.to_s, session_id, now, ttl, profile_id.to_s, content_title.to_s, episode_title.to_s]
      )

      if result == 1
        Result.new(success: true, session_id: session_id)
      else
        nil
      end
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while resuming session #{session_id}: #{e.message}")
      nil
    end

    # Renews the lease of an active session. The existence + ownership check
    # and the TTL renewal happen in a single Lua script so a stale ping can no
    # longer resurrect an expired session into an empty half-initialized hash.
    def ping_session(session_id, user = nil)
      return if session_id.blank?

      key = session_key(session_id)
      ttl = session_ttl_seconds

      result = redis.eval(
        ping_script,
        [key],
        [user ? user.id.to_s : "", Time.current.iso8601, ttl]
      )

      return nil unless result == 1

      payload = redis.hgetall(key)
      payload["ttl"] = [redis.pttl(key), 0].max / 1000
      payload["session_id"] = session_id
      payload
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while pinging session #{session_id}: #{e.message}")
      nil
    end

    # Terminates a session atomically (ownership check + DEL + SREM against the
    # account set). Still reads profile_id from the hash so callers can keep
    # identifying which profile owned the stream.
    def end_session(session_id, user = nil)
      return false if session_id.blank?

      expected_user_id = user ? user.id.to_s : ""
      user_key = user ? user_sessions_key(user.id) : ""

      result = redis.eval(
        end_script,
        [session_key(session_id), user_key],
        [expected_user_id, session_id]
      )

      result[0] == 1
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while ending session #{session_id}: #{e.message}")
      false
    end

    # Force-kills one of the user's sessions (used by "manage connected devices").
    # Atomic: returns :forbidden when the session belongs to another user.
    def kill_session(user, session_id)
      return false if session_id.blank?
      return :disabled unless SiteSetting.stream_force_kill_enabled

      result = redis.eval(
        kill_script,
        [session_key(session_id), user_sessions_key(user.id)],
        [user.id.to_s, session_id]
      )

      case result
      when 1 then true
      when -1 then :forbidden
      else false
      end
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while killing session #{session_id}: #{e.message}")
      false
    end

    # Lists every active PlaybackSession of the account (all profiles), with
    # profile_id and profile_name so the client can show who is connected.
    # Cleanup of stale set members happens lazily here and in the create script.
    def list_sessions(user)
      return [] unless SiteSetting.enable_stream_limit

      session_ids = redis.smembers(user_sessions_key(user.id))
      return [] if session_ids.empty?

      keys = session_ids.map { |session_id| session_key(session_id) }

      results = redis.pipelined do |pipeline|
        keys.each do |key|
          pipeline.pttl(key)
          pipeline.hgetall(key)
        end
      end

      ttls = results.each_slice(2).map(&:first)
      metas = results.each_slice(2).map(&:last)
      profile_names = profile_names_for(user)

      sessions = session_ids.each_with_index.filter_map do |session_id, index|
        ttl = ttls[index]

        if ttl <= 0
          redis.srem(user_sessions_key(user.id), session_id)
          next
        end

        meta = metas[index]
        profile_id = meta["profile_id"].presence

        {
          session_id: session_id,
          profile_id: profile_id,
          profile_name: profile_id && profile_names[profile_id],
          device_name: meta["device_name"],
          device_type: meta["device_type"],
          created_at: meta["created_at"],
          last_seen_at: meta["last_seen_at"],
          content_title: meta["content_title"].presence,
          episode_title: meta["episode_title"].presence,
          ttl: (ttl / 1000).to_i
        }
      end

      sessions.sort_by { |session| session[:last_seen_at].to_s }.reverse
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while listing sessions for user #{user.id}: #{e.message}")
      []
    end

    # Background cleanup: removes expired members from every `stream:user_sessions:*`
    # set so a long-lived account set does not keep growing. Batch-scans in chunks
    # of 100 to keep memory pressure low. Returns the number of members removed.
    def prune_stale_members
      return 0 unless SiteSetting.enable_stream_limit

      cleaned = 0
      redis.scan_each(match: "stream:user_sessions:*") do |set_key|
        session_ids = redis.smembers(set_key)
        next if session_ids.empty?

        session_ids.each_slice(100) do |batch|
          keys = batch.map { |session_id| session_key(session_id) }
          ttls = redis.pipelined do |pipeline|
            keys.each { |key| pipeline.pttl(key) }
          end

          expired = batch.select.with_index { |_, index| ttls[index].to_i <= 0 }
          next if expired.empty?

          redis.srem(set_key, expired)
          cleaned += expired.length
        end
      end
      cleaned
    rescue Redis::BaseError => e
      Rails.logger.error("[StreamSessionManager] Redis error while pruning stale sessions: #{e.message}")
      0
    end

    private

    def redis
      @redis ||= Cache.new.redis
    end

    def session_key(session_id)
      "stream:session:#{session_id}"
    end

    # The stream limit is enforced per account: every profile of the user shares
    # the same set of active sessions.
    def user_sessions_key(user_id)
      "stream:user_sessions:#{user_id}"
    end

    # Idempotency mapping: `stream:client_request:<user_id>:<client_request_id>` ->
    # session_id. Lets a retried /watch request reuse the session it already
    # reserved instead of counting twice against the limit.
    def client_request_key(user_id, client_request_id)
      return "" if client_request_id.blank?

      "stream:client_request:#{user_id}:#{client_request_id}"
    end

    def profile_names_for(user)
      Profile.where(user_id: user.id).pluck(:id, :name).to_h
    end

    def resume_script
      <<~LUA
        local key = KEYS[1]
        local user_key = KEYS[2]
        local expected_user_id = ARGV[1]
        local session_id = ARGV[2]
        local now = ARGV[3]
        local ttl = tonumber(ARGV[4])
        local profile_id = ARGV[5]
        local content_title = ARGV[6]
        local episode_title = ARGV[7]

        if redis.call("EXISTS", key) == 0 then
          return 0
        end

        local owner_id = redis.call("HGET", key, "user_id") or ""
        if owner_id ~= expected_user_id then
          return 0
        end

        redis.call("HSET", key, "last_seen_at", now)
        if profile_id and profile_id ~= "" then
          redis.call("HSET", key, "profile_id", profile_id)
        end
        if content_title and content_title ~= "" then
          redis.call("HSET", key, "content_title", content_title)
        end
        if episode_title and episode_title ~= "" then
          redis.call("HSET", key, "episode_title", episode_title)
        end
        redis.call("PEXPIRE", key, ttl * 1000)
        redis.call("SADD", user_key, session_id)
        return 1
      LUA
    end

    def ping_script
      <<~LUA
        local key = KEYS[1]
        local expected_user_id = ARGV[1]
        local now = ARGV[2]
        local ttl = tonumber(ARGV[3])

        if redis.call("EXISTS", key) == 0 then
          return 0
        end

        local owner_id = redis.call("HGET", key, "user_id") or ""
        if expected_user_id ~= "" and owner_id ~= expected_user_id then
          return 0
        end

        redis.call("HSET", key, "last_seen_at", now)
        redis.call("PEXPIRE", key, ttl * 1000)
        return 1
      LUA
    end

    def end_script
      <<~LUA
        local key = KEYS[1]
        local user_key = KEYS[2]
        local expected_user_id = ARGV[1]
        local session_id = ARGV[2]

        if redis.call("EXISTS", key) == 0 then
          return {0, ""}
        end

        local owner_id = redis.call("HGET", key, "user_id") or ""
        local profile_id = redis.call("HGET", key, "profile_id") or ""

        if expected_user_id ~= "" and owner_id ~= expected_user_id then
          return {0, ""}
        end

        if user_key == "" then
          user_key = "stream:user_sessions:" .. owner_id
        end

        redis.call("DEL", key)
        redis.call("SREM", user_key, session_id)

        return {1, profile_id}
      LUA
    end

    def kill_script
      <<~LUA
        local key = KEYS[1]
        local user_key = KEYS[2]
        local expected_user_id = ARGV[1]
        local session_id = ARGV[2]

        if redis.call("EXISTS", key) == 0 then
          return 0
        end

        local owner_id = redis.call("HGET", key, "user_id") or ""

        if owner_id ~= expected_user_id then
          return -1
        end

        redis.call("DEL", key)
        redis.call("SREM", user_key, session_id)
        return 1
      LUA
    end

    def session_create_script
      <<~LUA
        local user_sessions_key = KEYS[1]
        local session_key = KEYS[2]
        local client_request_key = KEYS[3]
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
        local content_title = ARGV[11]
        local episode_title = ARGV[12]
        local client_request_id = ARGV[13]

        -- Idempotency: if this client already reserved a session for this request,
        -- reuse it instead of reserving a second slot.
        if client_request_key ~= "" then
          local existing = redis.call("GET", client_request_key)
          if existing then
            local existing_key = "stream:session:" .. existing
            if redis.call("EXISTS", existing_key) == 1 then
              redis.call("HSET", existing_key, "last_seen_at", last_seen_at)
              redis.call("PEXPIRE", existing_key, ttl * 1000)
              redis.call("SADD", user_sessions_key, existing)
              return cjson.encode({ status = "created", session_id = existing })
            end
            redis.call("DEL", client_request_key)
          end
        end

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
              local info = redis.call("HMGET", key, "profile_id", "device_name", "device_type", "last_seen_at", "content_title", "episode_title")
              table.insert(active_sessions, {
                session_id = sid,
                profile_id = info[1],
                device_name = info[2],
                device_type = info[3],
                last_seen_at = info[4],
                content_title = info[5],
                episode_title = info[6],
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
          "last_seen_at", last_seen_at,
          "content_title", content_title,
          "episode_title", episode_title,
          "client_request_id", client_request_id
        )
        redis.call("PEXPIRE", session_key, ttl * 1000)
        redis.call("SADD", user_sessions_key, session_id)
        if client_request_key ~= "" then
          redis.call("SET", client_request_key, session_id, "PX", ttl * 1000)
        end

        return cjson.encode({ status = "created", session_id = session_id })
      LUA
    end

    def max_simultaneous_streams_per_user
      SiteSetting.max_simultaneous_streams_per_user.to_i.clamp(1, 10)
    end

    # The lease must survive several missed pings (background-tab throttling,
    # slow networks) before the slot is released, so the TTL is at least
    # 3x the ping interval.
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
