# frozen_string_literal: true

class RenameTypeColumnInProfiles < ActiveRecord::Migration[7.0]
  def change
    rename_column :profiles, :type, :profile_type
  end
end
