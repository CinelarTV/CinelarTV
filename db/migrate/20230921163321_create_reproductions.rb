# frozen_string_literal: true

class CreateReproductions < ActiveRecord::Migration[7.0]
  def change
    create_table :reproductions do |t|
      t.references :profile, type: :uuid, null: false, foreign_key: true
      t.references :content, type: :uuid, null: false, foreign_key: true
      t.datetime :played_at, null: false
      t.string :country_code, null: false

      t.timestamps
    end
  end
end
