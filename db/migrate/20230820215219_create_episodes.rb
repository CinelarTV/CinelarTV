# frozen_string_literal: true

class CreateEpisodes < ActiveRecord::Migration[7.0]
  def change
    create_table :episodes, id: :uuid do |t|
      t.string :title
      t.string :description
      t.string :url
      t.references :season, null: false, foreign_key: true

      t.timestamps
    end
  end
end
