# frozen_string_literal: true

class FixImageVariantsImageableIdType < ActiveRecord::Migration[7.2]
  def up
    execute "DELETE FROM image_variants"

    remove_index :image_variants, name: "idx_image_variants_on_lookup"
    remove_index :image_variants, name: "index_image_variants_on_imageable"

    remove_column :image_variants, :imageable_id

    add_column :image_variants, :imageable_id, :uuid, null: false

    add_index :image_variants,
              %i[imageable_type imageable_id image_type variant format],
              unique: true,
              name: "idx_image_variants_on_lookup"

    add_index :image_variants, %i[imageable_type imageable_id], name: "index_image_variants_on_imageable"
  end

  def down
    remove_index :image_variants, name: "idx_image_variants_on_lookup"
    remove_index :image_variants, name: "index_image_variants_on_imageable"

    remove_column :image_variants, :imageable_id

    add_column :image_variants, :imageable_id, :bigint, null: false

    add_index :image_variants,
              %i[imageable_type imageable_id image_type variant format],
              unique: true,
              name: "idx_image_variants_on_lookup"

    add_index :image_variants, %i[imageable_type imageable_id], name: "index_image_variants_on_imageable"
  end
end
