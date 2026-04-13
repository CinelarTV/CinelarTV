# frozen_string_literal: true

# Create watch party sessions and users tables
class CreateWatchPartyTables < ActiveRecord::Migration[7.1]
  def change
    create_table :watch_party_sessions do |t|
      t.string :content_id, null: false
      t.uuid :host_id, null: false
      t.uuid :user_id, null: false
      t.float :playback_current_time, default: 0.0
      t.boolean :is_playing, default: false
      t.datetime :started_at
      t.datetime :ended_at
      t.datetime :last_sync_at
      t.timestamps
    end

    add_index :watch_party_sessions, :content_id
    add_index :watch_party_sessions, :host_id
    add_index :watch_party_sessions, :user_id

    create_table :watch_party_session_users do |t|
      t.references :watch_party_session, type: :bigint, null: false, foreign_key: true
      t.uuid :user_id, null: false
      t.boolean :is_host, default: false
      t.datetime :joined_at
      t.timestamps
    end

    add_index :watch_party_session_users, :watch_party_session_id
    add_index :watch_party_session_users, [:watch_party_session_id, :user_id], unique: true
    add_index :watch_party_session_users, :user_id
    
    # Add foreign key constraints
    add_foreign_key :watch_party_sessions, :users, column: :host_id, primary_key: :id
    add_foreign_key :watch_party_sessions, :users, column: :user_id, primary_key: :id
    add_foreign_key :watch_party_session_users, :users, column: :user_id, primary_key: :id
  end
end
