# frozen_string_literal: true

class AddScheduledLaunchAtToContents < ActiveRecord::Migration[7.2]
  def change
    add_column :contents, :scheduled_launch_at, :datetime
    add_index :contents, :scheduled_launch_at,
              where: "scheduled_launch_at IS NOT NULL AND available = false",
              name: "index_contents_on_scheduled_launch_pending"
  end
end
