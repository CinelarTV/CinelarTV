# frozen_string_literal: true

class AddExposedToClientToSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :exposed_to_client, :boolean, default: false
  end
end
