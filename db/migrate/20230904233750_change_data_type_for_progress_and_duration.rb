# frozen_string_literal: true

class ChangeDataTypeForProgressAndDuration < ActiveRecord::Migration[7.0]
  def change
    change_column :continue_watchings, :progress, :numeric
    change_column :continue_watchings, :duration, :numeric
  end
end
