# frozen_string_literal: true

class AddMonitoringFieldsToVideoSources < ActiveRecord::Migration[7.2]
  def change
    add_column :video_sources, :last_checked_at, :datetime
    add_column :video_sources, :media_status, :string, default: "verified"
    add_column :video_sources, :failure_count, :integer, default: 0

    add_index :video_sources, :media_status
    add_index :video_sources, :last_checked_at
  end
end
