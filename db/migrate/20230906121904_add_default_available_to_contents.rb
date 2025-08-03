# frozen_string_literal: true

class AddDefaultAvailableToContents < ActiveRecord::Migration[7.0]
  def change
    change_column_default :contents, :available, true
  end
end
