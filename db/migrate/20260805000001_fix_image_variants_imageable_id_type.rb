# frozen_string_literal: true

class FixImageVariantsImageableIdType < ActiveRecord::Migration[7.2]
  def up
    execute "DELETE FROM image_variants"

    change_column :image_variants, :imageable_id, :uuid, null: false
  end

  def down
    change_column :image_variants, :imageable_id, :bigint, null: false
  end
end
