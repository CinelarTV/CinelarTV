# frozen_string_literal: true

class CreateSeasons < ActiveRecord::Migration[7.0]
  def change
    create_table :seasons do |t|
      t.string :title
      t.string :description
      t.references :content, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
