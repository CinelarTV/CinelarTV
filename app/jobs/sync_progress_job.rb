# frozen_string_literal: true

class SyncProgressJob < ApplicationJob
  queue_as :default

  def perform(profile_id, content_id, episode_id, progress, duration)
    cw = ContinueWatching.find_or_initialize_by(
      profile_id: profile_id,
      content_id: content_id,
      episode_id: episode_id
    )

    # Solo actualizar si el dato de la base de datos es más antiguo que el dato recibido
    # O si es un registro nuevo.
    if cw.new_record? || cw.last_watched_at.nil? || cw.last_watched_at < Time.current
      cw.update!(
        progress: progress,
        duration: duration,
        last_watched_at: Time.current
      )
    end
  end
end
