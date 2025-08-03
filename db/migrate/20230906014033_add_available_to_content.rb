# frozen_string_literal: true

class AddAvailableToContent < ActiveRecord::Migration[7.0]
  def change
    add_column :contents, :available, :boolean
  end
end
