# frozen_string_literal: true

class CreateContentAnalytics < ActiveRecord::Migration[7.2]
  def change
    create_table :content_analytics, id: :uuid do |t|
      t.references :content, null: false, foreign_key: true, type: :uuid
      t.integer :total_views, default: 0, null: false
      t.float :total_seconds_watched, default: 0.0, null: false
      t.integer :unique_profiles, default: 0, null: false
      t.float :completion_rate, default: 0.0, null: false
      t.float :avg_watch_percentage, default: 0.0, null: false
      t.datetime :last_watched_at

      t.timestamps
    end

    add_index :content_analytics, :total_views
    add_index :content_analytics, :last_watched_at
  end
end
