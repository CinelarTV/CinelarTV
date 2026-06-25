# frozen_string_literal: true

class AddVideoPerformanceIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :episodes, %i[season_id position], name: "index_episodes_on_season_id_and_position"
    add_index :seasons, %i[content_id position], name: "index_seasons_on_content_id_and_position"
    add_index :segments, %i[segmentable_type segmentable_id start_time],
              name: "index_segments_on_type_and_id_and_start_time"
    add_index :continue_watchings, %i[profile_id last_watched_at],
              name: "index_continue_watchings_on_profile_id_and_last_watched_at"
  end
end
