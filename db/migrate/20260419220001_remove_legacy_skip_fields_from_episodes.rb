# frozen_string_literal: true

class RemoveLegacySkipFieldsFromEpisodes < ActiveRecord::Migration[7.0]
  def change
    remove_column :episodes, :skip_intro_start, :float
    remove_column :episodes, :skip_intro_end, :float
    remove_column :episodes, :episode_end, :float
  end
end
