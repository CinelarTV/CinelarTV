# frozen_string_literal: true

class AddEpisodeIdToReproductions < ActiveRecord::Migration[7.2]
  def change
    add_reference :reproductions, :episode, type: :uuid, foreign_key: true, null: true
  end
end
