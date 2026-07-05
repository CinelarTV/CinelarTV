# frozen_string_literal: true

class CreateCastMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :cast_members, id: :uuid do |t|
      t.references :content, null: false, foreign_key: true, type: :uuid
      t.references :person, null: false, foreign_key: true, type: :uuid
      t.string :character_name
      t.integer :order
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :cast_members, [:content_id, :person_id], unique: true
    add_index :cast_members, [:content_id, :order]
  end
end
