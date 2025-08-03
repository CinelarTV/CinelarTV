# frozen_string_literal: true

class CreateProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :profiles, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :name
      t.string :profile_type
      t.string :avatar_id

      t.timestamps
    end
  end
end
