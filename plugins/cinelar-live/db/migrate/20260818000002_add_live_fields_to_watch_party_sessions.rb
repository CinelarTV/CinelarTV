# frozen_string_literal: true

class AddLiveFieldsToWatchPartySessions < ActiveRecord::Migration[7.2]
  def change
    add_reference :watch_party_sessions, :live_event,
                  foreign_key: { to_table: :live_events }, null: true
    add_column :watch_party_sessions, :is_public, :boolean, default: false, null: false
    add_column :watch_party_sessions, :playback_position, :float, default: 0.0
    add_column :watch_party_sessions, :last_playback_update_at, :datetime
    add_column :watch_party_sessions, :last_activity_at, :datetime
    add_index :watch_party_sessions, [:is_public, :ended_at]
  end
end
