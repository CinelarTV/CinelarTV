# frozen_string_literal: true

class AddTmdbIdToSeasonsAndEpisodes < ActiveRecord::Migration[7.2]
  def change
    add_column :seasons, :tmdb_id, :integer
    add_index :seasons, :tmdb_id, unique: true, where: "tmdb_id IS NOT NULL"

    add_column :episodes, :tmdb_id, :integer
    add_index :episodes, :tmdb_id, unique: true, where: "tmdb_id IS NOT NULL"
  end
end
