# frozen_string_literal: true

class AddTmdbIdToCategories < ActiveRecord::Migration[7.0]
  def change
    add_column :categories, :tmdb_id, :integer
    add_index :categories, :tmdb_id, unique: true, where: "tmdb_id IS NOT NULL"
  end
end
