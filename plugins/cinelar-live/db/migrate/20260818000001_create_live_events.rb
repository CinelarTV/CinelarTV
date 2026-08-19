# frozen_string_literal: true

class CreateLiveEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :live_events, id: :bigint do |t|
      t.references :content, null: false, foreign_key: true, type: :uuid
      t.references :organizer, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :title
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :estimated_end_at
      t.integer :status, default: 0, null: false
      t.integer :max_participants
      t.boolean :is_public, default: true, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :live_events, :status
    add_index :live_events, [:status, :starts_at]
  end
end
