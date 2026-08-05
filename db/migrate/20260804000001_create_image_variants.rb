# frozen_string_literal: true

class CreateImageVariants < ActiveRecord::Migration[7.2]
  def change
    create_table :image_variants, id: :uuid do |t|
      t.references :imageable, polymorphic: true, null: false
      t.string :image_type, null: false
      t.string :variant, null: false
      t.string :format, null: false
      t.string :url, null: false
      t.timestamps
    end

    add_index :image_variants,
              %i[imageable_type imageable_id image_type variant format],
              unique: true,
              name: "idx_image_variants_on_lookup"

    add_index :image_variants, %i[image_type variant format]
  end
end
