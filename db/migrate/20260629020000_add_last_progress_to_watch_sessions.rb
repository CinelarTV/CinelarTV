# frozen_string_literal: true

class AddLastProgressToWatchSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :watch_sessions, :last_progress, :float, default: 0.0, null: false
  end
end
