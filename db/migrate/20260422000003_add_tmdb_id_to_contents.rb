# frozen_string_literal: true

class AddTmdbIdToContents < ActiveRecord::Migration[7.0]
  def change
    add_column :contents, :tmdb_id, :integer
    add_index :contents, :tmdb_id
  end
end
