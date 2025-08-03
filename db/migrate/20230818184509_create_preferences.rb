# frozen_string_literal: true

class CreatePreferences < ActiveRecord::Migration[7.0]
  def change
    create_table :preferences do |t|
      t.references :profile, type: :uuid, null: false, foreign_key: true
      t.string :key
      t.string :value

      t.timestamps
    end
  end
end
