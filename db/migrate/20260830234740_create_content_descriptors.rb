# frozen_string_literal: true

class CreateContentDescriptors < ActiveRecord::Migration[7.2]
  def change
    create_table :content_descriptors, id: :uuid do |t|
      t.string :key, null: false
      t.jsonb :name_translations, default: {}
      t.jsonb :description_translations, default: {}
      t.string :category, null: false
      t.integer :severity_level, default: 1
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :content_descriptors, :key, unique: true
  end
end
