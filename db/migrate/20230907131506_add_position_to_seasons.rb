# frozen_string_literal: true

class AddPositionToSeasons < ActiveRecord::Migration[7.0]
  def change
    add_column :seasons, :position, :integer
  end
end
