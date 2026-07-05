# frozen_string_literal: true

class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people, id: :uuid do |t|
      t.integer :tmdb_id, null: false
      t.string :name, null: false
      t.string :profile_path
      t.string :known_for_department, default: "Acting"
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :people, :tmdb_id, unique: true
  end
end
