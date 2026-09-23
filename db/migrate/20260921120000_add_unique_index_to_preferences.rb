# frozen_string_literal: true

class AddUniqueIndexToPreferences < ActiveRecord::Migration[7.2]
  def change
    add_index :preferences, [:profile_id, :key], unique: true
  end
end
