# frozen_string_literal: true

class Live::StartScheduledEventsJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    Live::Event.where(status: :scheduled)
               .where("starts_at <= ?", Time.current)
               .find_each { |event| start_event(event) }
  end

  private

  def start_event(event)
    ActiveRecord::Base.transaction do
      event.update!(status: :starting)

      elapsed = (Time.current - event.starts_at).to_f
      elapsed = [elapsed, 0].max

      session = WatchParty::Session.create!(
        content_id: event.content_id,
        host_id: event.organizer_id,
        user_id: event.organizer_id,
        is_public: true,
        live_event_id: event.id,
        started_at: event.starts_at,
        playback_position: elapsed,
        playback_current_time: elapsed,
        is_playing: true,
        last_sync_at: Time.current,
        last_activity_at: Time.current,
        last_playback_update_at: Time.current
      )

      event.update!(status: :live)

      if defined?(MessageBus)
        MessageBus.publish("/live/event/#{event.id}", {
          type: "event_started",
          event_id: event.id,
          session_id: session.id
        })

        MessageBus.publish("/live/status", {
          type: "event_started",
          event_id: event.id,
          content_id: event.content_id,
          title: event.title || event.content.title
        })
      end

      Rails.logger.info("[Live] Event #{event.id} started → session #{session.id}")
    end
  rescue => e
    Rails.logger.error("[Live] Failed to start event #{event.id}: #{e.message}")
    event.update!(status: :cancelled) if event.scheduled? || event.starting?
  end
end
