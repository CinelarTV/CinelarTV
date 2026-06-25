# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[7.0]
  def change
    # Fase 1 — Columnas más filtradas del sistema
    add_index :contents, :available, where: "available = true", name: "index_contents_on_available_true"
    add_index :contents, :content_type

    # Reports: reproductions y likes
    add_index :reproductions, :country_code
    add_index :reproductions, :played_at
    add_index :likes, :updated_at

    # Reports: users
    add_index :users, :created_at

    # ContinueWatching: ordering por last_watched_at
    add_index :continue_watchings, :last_watched_at

    # VideoSources: status usado en transcoding jobs
    add_index :video_sources, :status
  end
end
