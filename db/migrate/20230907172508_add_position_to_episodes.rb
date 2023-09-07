# frozen_string_literal: true

class AddPositionToEpisodes < ActiveRecord::Migration[7.0]
  def change
    add_column :episodes, :position, :integer
  end
end
