# frozen_string_literal: true

class Live::CheckEventCompletionJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  COMPLETION_TOLERANCE = 5.seconds
  ACTIVITY_TIMEOUT = 10.minutes
  NO_DURATION_SAFETY = 4.hours

  def perform
    Live::Event.where(status: :live).find_each { |event| check(event) }
  end

  private

  def check(event)
    session = event.watch_party_session
    return unless session
    return if session.ended_at.present?

    estimated = Live::DurationEstimator.estimate(event.content_id)
    position = Live::PositionCalculator.current_position(session)

    if estimated[:duration] && position >= (estimated[:duration] + COMPLETION_TOLERANCE)
      end_event(event, session)
      return
    end

    if session.last_sync_at && session.last_sync_at < ACTIVITY_TIMEOUT.ago
      end_event(event, session)
      return
    end

    if estimated[:duration].nil? && position >= NO_DURATION_SAFETY
      end_event(event, session)
    end
  end

  def end_event(event, session)
    session.update!(ended_at: Time.current, is_playing: false)
    event.update!(status: :ended)

    if defined?(MessageBus)
      MessageBus.publish("/watchparty/#{session.id}", { type: "session_ended" })
      MessageBus.publish("/live/event/#{event.id}", { type: "event_ended" })
      MessageBus.publish("/live/status", { type: "event_ended", event_id: event.id })
    end

    Live::ActivityTracker.reset(session.id)
    Rails.logger.info("[Live] Event #{event.id} ended → session #{session.id}")
  end
end
