# frozen_string_literal: true

# Shared logic for expiring the currently selected profile after inactivity.
#
# Storage:
# - Web (Devise session): session[:current_profile_id] + session[:profile_last_activity_at]
# - Doorkeeper (mobile/TV Bearer): oauth_access_tokens.current_profile_id + profile_last_activity_at
#
# Setting: SiteSetting.profile_selection_timeout_hours (0 = never expire)
module ProfileSelectionExpiry
  extend ActiveSupport::Concern

  ACTIVITY_TOUCH_INTERVAL = 5.minutes

  # nil => never expire
  def profile_selection_timeout_seconds
    hours = SiteSetting.profile_selection_timeout_hours.to_i
    hours.positive? ? hours.hours : nil
  end

  def coerce_profile_time(value)
    return nil if value.blank?
    return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone) || value.is_a?(DateTime)

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  # Blank last_activity with a selected profile is treated as not expired
  # (grace after deploy / first touch). Expired only when timestamp is past TTL.
  def profile_selection_expired?(last_activity_at)
    timeout = profile_selection_timeout_seconds
    return false if timeout.nil?

    last = coerce_profile_time(last_activity_at)
    return false if last.blank?

    last < timeout.ago
  end

  def raw_profile_id
    if using_doorkeeper?
      doorkeeper_token&.current_profile_id
    else
      session[:current_profile_id]
    end
  end

  def profile_activity_last_at
    raw = if using_doorkeeper?
            doorkeeper_token&.profile_last_activity_at
          else
            session[:profile_last_activity_at]
          end
    coerce_profile_time(raw)
  end

  # Profile id after applying expiry. Clears storage when expired.
  def resolved_profile_id
    profile_id = raw_profile_id
    return nil if profile_id.blank?

    if profile_selection_expired?(profile_activity_last_at)
      clear_current_profile!
      return nil
    end

    profile_id
  end

  def clear_current_profile!
    if using_doorkeeper?
      doorkeeper_token&.update_columns(current_profile_id: nil, profile_last_activity_at: nil)
    else
      session[:current_profile_id] = nil
      session[:profile_last_activity_at] = nil
    end
  end

  def write_profile_selection!(profile_id)
    now = profile_id.present? ? Time.current : nil

    if using_doorkeeper?
      doorkeeper_token&.update_columns(
        current_profile_id: profile_id,
        profile_last_activity_at: now
      )
    else
      session[:current_profile_id] = profile_id
      session[:profile_last_activity_at] = now
    end
  end

  # Refresh last-activity timestamp for the active profile selection (throttled).
  def touch_profile_activity!
    return if profile_selection_timeout_seconds.nil?

    last = profile_activity_last_at
    now = Time.current
    return if last.present? && (now - last) < ACTIVITY_TOUCH_INTERVAL

    if profile_selection_expired?(last)
      clear_current_profile!
      return
    end

    return if raw_profile_id.blank?

    if using_doorkeeper?
      doorkeeper_token&.update_column(:profile_last_activity_at, now)
    else
      session[:profile_last_activity_at] = now
    end
  end
end
