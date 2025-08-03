# frozen_string_literal: true

class AddSkipIntroAndEpisodeEndToEpisodes < ActiveRecord::Migration[7.0]
  def change
    # Episodes uses float on video time, so we use float here too
    add_column :episodes, :skip_intro_start, :float
    add_column :episodes, :skip_intro_end, :float
    add_column :episodes, :episode_end, :float # This is the end of the episode, not the end of the video
  end
end
