# frozen_string_literal: true

class AddStatusAndTempPathToVideoSources < ActiveRecord::Migration[7.2]
  def change
    add_column :video_sources, :status, :string
    add_column :video_sources, :temp_path, :string
  end
end
