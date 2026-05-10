# frozen_string_literal: true

class CreateContentCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :content_categories do |t|
      t.uuid :content_id, null: false
      t.integer :category_id, null: false

      t.timestamps
    end

    add_index :content_categories, :content_id
    add_index :content_categories, :category_id
    add_index :content_categories, [:content_id, :category_id], unique: true

    add_foreign_key :content_categories, :contents, on_delete: :cascade
    add_foreign_key :content_categories, :categories, on_delete: :cascade
  end
end
