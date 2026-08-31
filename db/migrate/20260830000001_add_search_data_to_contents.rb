# frozen_string_literal: true

class AddSearchDataToContents < ActiveRecord::Migration[7.2]
  def up
    add_column :contents, :search_data, :tsvector

    execute <<~SQL
      UPDATE contents SET search_data =
        setweight(to_tsvector('simple', immutable_unaccent(coalesce(title, '')::text)), 'A') ||
        setweight(to_tsvector('simple', immutable_unaccent(coalesce(description, '')::text)), 'B')
    SQL

    add_index :contents, :search_data, using: :gin, name: :index_contents_on_search_data
  end

  def down
    remove_index :contents, name: :index_contents_on_search_data
    remove_column :contents, :search_data
  end
end
