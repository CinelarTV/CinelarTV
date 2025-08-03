# frozen_string_literal: true

class CreateContinueWatchings < ActiveRecord::Migration[7.0]
  def change
    create_table :continue_watchings do |t|
      t.references :profile, type: :uuid, null: false, foreign_key: true
      t.references :content, type: :uuid, null: false, foreign_key: true
      t.references :episode, type: :uuid, null: true, foreign_key: true
      t.integer :progress, null: false, default: 0
      t.integer :duration, null: false, default: 0
      t.datetime :last_watched_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.boolean :finished, null: false, default: false

      t.timestamps
    end

    add_index :continue_watchings, %i[profile_id content_id episode_id], unique: true,
                                                                         name: 'unique_continue_watchings_index'
  end
end
