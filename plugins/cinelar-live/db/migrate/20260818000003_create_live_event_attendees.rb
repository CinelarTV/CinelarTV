# frozen_string_literal: true

class CreateLiveEventAttendees < ActiveRecord::Migration[7.2]
  def change
    create_table :live_event_attendees, id: :bigint do |t|
      t.references :live_event, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true, type: :uuid
      t.datetime :notified_at
      t.timestamps
    end

    add_index :live_event_attendees, [:live_event_id, :profile_id], unique: true
  end
end
