# frozen_string_literal: true

class FixImageVariantsImageableIdType < ActiveRecord::Migration[7.2]
  def up
    execute "DELETE FROM image_variants"

    execute "ALTER TABLE image_variants ALTER COLUMN imageable_id DROP DEFAULT"
    execute "ALTER TABLE image_variants ALTER COLUMN imageable_id TYPE uuid USING imageable_id::uuid"
  end

  def down
    change_column :image_variants, :imageable_id, :bigint, null: false
  end
end
