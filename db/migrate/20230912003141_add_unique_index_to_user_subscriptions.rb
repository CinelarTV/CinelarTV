# frozen_string_literal: true

class AddUniqueIndexToUserSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_index :user_subscriptions, :user_id, unique: true
  end
end
