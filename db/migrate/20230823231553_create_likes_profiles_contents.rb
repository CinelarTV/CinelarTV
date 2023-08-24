# frozen_string_literal: true

class CreateLikesProfilesContents < ActiveRecord::Migration[7.0]
  def change
    create_table :likes do |t|
      t.references :profile, type: :uuid, foreign_key: true
      t.references :content, type: :uuid, foreign_key: true
      t.timestamps
    end
  end
end
