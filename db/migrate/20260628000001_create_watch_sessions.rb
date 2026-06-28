# frozen_string_literal: true

class CreateWatchSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :watch_sessions, id: :uuid do |t|
      t.references :profile, null: false, foreign_key: true, type: :uuid
      t.references :content, null: false, foreign_key: true, type: :uuid
      t.references :episode, foreign_key: true, type: :uuid
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.float :duration_watched, default: 0.0, null: false
      t.float :total_duration, default: 0.0, null: false
      t.boolean :completed, default: false, null: false
      t.string :country_code

      t.timestamps
    end

    add_index :watch_sessions, :started_at
    add_index :watch_sessions, :completed
    add_index :watch_sessions, [:content_id, :started_at]
    add_index :watch_sessions, [:profile_id, :started_at]
  end
end
