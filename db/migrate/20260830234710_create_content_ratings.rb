# frozen_string_literal: true

class CreateContentRatings < ActiveRecord::Migration[7.2]
  def change
    create_table :content_ratings, id: :uuid do |t|
      t.string :code, null: false
      t.string :system, null: false
      t.jsonb :name_translations, default: {}
      t.jsonb :description_translations, default: {}
      t.integer :min_age
      t.string :color, default: "#ffffff"
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :content_ratings, :code, unique: true
  end
end
