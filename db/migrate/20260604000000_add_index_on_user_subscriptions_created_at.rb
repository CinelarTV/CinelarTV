# frozen_string_literal: true

class AddIndexOnUserSubscriptionsCreatedAt < ActiveRecord::Migration[7.0]
  def change
    add_index :user_subscriptions, :created_at
  end
end
