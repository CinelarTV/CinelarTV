# frozen_string_literal: true

class CreateSegments < ActiveRecord::Migration[7.0]
  def change
    create_table :segments do |t|
      t.float :start_time
      t.float :end_time
      t.string :segment_type, null: false
      t.string :segmentable_type, null: false
      t.integer :segmentable_id, null: false
      t.timestamps

      t.index [:segmentable_type, :segmentable_id]
      t.index :segment_type
    end
  end
end
