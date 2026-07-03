# frozen_string_literal: true

class AddTrailerToVideoSources < ActiveRecord::Migration[7.2]
  def change
    add_column :video_sources, :trailer, :boolean, default: false, null: false
    add_index :video_sources, [:videoable_id, :videoable_type, :trailer],
              name: "index_video_sources_on_videoable_and_trailer"
  end
end
