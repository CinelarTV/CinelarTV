# frozen_string_literal: true

class ChangeProgressAndDurationToFloat < ActiveRecord::Migration[6.0]
  def change
    change_column :continue_watchings, :progress, :float
    change_column :continue_watchings, :duration, :float
  end
end
