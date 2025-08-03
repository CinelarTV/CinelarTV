# frozen_string_literal: true

class ChangeVideoableIdToUuidInVideoSources < ActiveRecord::Migration[7.0]
  def change
    change_column :video_sources, :videoable_id, :uuid, using: "videoable_id::uuid"
  end
end
