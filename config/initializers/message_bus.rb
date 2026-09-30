# frozen_string_literal: true

# config/initializers/message_bus.rb

# Test Redis connectivity and fall back to :memory if unavailable
begin
  redis_url = ENV["REDIS_URL"]
  if redis_url.present?
    redis = Redis.new(url: redis_url)
    redis.ping
  else
    # No REDIS_URL configured, use memory backend
    MessageBus.configure(backend: :memory)
  end
rescue Redis::CannotConnectError, Redis::ConnectionError, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
  Rails.logger.warn "Redis unavailable for MessageBus (#{e.class}: #{e.message}). Falling back to :memory backend."
  MessageBus.configure(backend: :memory)
end

MessageBus.user_id_lookup do |env|
  # Resolve current profile id for MessageBus:
  # 1) prefer Rails session `:current_profile_id`
  # 2) else, accept an API Bearer token and read current_profile_id from the token record
  # Expired profile selections (inactivity timeout) resolve to -1.
  request = Rack::Request.new(env)
  profile_id = nil

  begin
    timeout_hours = SiteSetting.profile_selection_timeout_hours.to_i
    timeout = timeout_hours.positive? ? timeout_hours.hours : nil

    parse_time = lambda do |value|
      next nil if value.blank?
      next value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    if request.session && request.session[:current_profile_id].present?
      last_activity = parse_time.call(request.session[:profile_last_activity_at])
      expired = timeout && last_activity.present? && last_activity < timeout.ago
      profile_id = expired ? nil : request.session[:current_profile_id]
    else
      auth = request.get_header('HTTP_AUTHORIZATION') || request.get_header('Authorization')
      if auth.present?
        m = auth.match(/\ABearer\s+(.+)\z/i)
        if m
          token_str = m[1]
          token = Doorkeeper::AccessToken.find_by(token: token_str)
          if token&.current_profile_id.present?
            last_activity = parse_time.call(token.profile_last_activity_at)
            expired = timeout && last_activity.present? && last_activity < timeout.ago
            profile_id = expired ? nil : token.current_profile_id
          end
        end
      end
    end
  rescue => e
    Rails.logger.error("MessageBus user_id_lookup failed: #{e.class} - #{e.message}")
  end

  Rails.logger.info("MessageBus user_id_lookup resolved profile_id: #{profile_id || -1}")
  profile_id || -1
end
