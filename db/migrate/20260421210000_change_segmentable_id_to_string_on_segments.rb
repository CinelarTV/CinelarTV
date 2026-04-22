# frozen_string_literal: true

class ChangeSegmentableIdToStringOnSegments < ActiveRecord::Migration[7.0]
  def up
    change_column_null :segments, :segmentable_id, true
    change_column :segments, :segmentable_id, :string, using: 'segmentable_id::text'
    execute <<~SQL
      DELETE FROM segments WHERE segmentable_id = '0';
    SQL
    change_column_null :segments, :segmentable_id, false
  end

  def down
    add_column :segments, :segmentable_id_int, :integer
    execute <<~SQL
      UPDATE segments
      SET segmentable_id_int = segmentable_id::integer
      WHERE segmentable_id ~ '^[0-9]+$';
    SQL
    remove_column :segments, :segmentable_id
    rename_column :segments, :segmentable_id_int, :segmentable_id
  end
end
