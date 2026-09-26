# frozen_string_literal: true

class CreateContentBadges < ActiveRecord::Migration[7.2]
  def change
    create_table :content_badges, id: :uuid do |t|
      t.references :content, type: :uuid, null: false, foreign_key: true
      t.string :badge_type, null: false
      t.string :label, null: false
      t.string :icon
      t.string :color
      t.datetime :expires_at
      t.integer :position, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :content_badges, [:content_id, :position]
    add_index :content_badges, :badge_type
  end
end
