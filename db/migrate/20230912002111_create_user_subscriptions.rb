# frozen_string_literal: true

class CreateUserSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :user_subscriptions do |t|
      t.uuid :user_id, null: false
      t.integer :order_id
      t.integer :order_item_id
      t.integer :product_id
      t.integer :variant_id
      t.string :product_name
      t.string :variant_name
      t.string :user_name
      t.string :user_email
      t.string :status
      t.string :status_formatted
      t.string :card_brand
      t.string :card_last_four
      t.boolean :cancelled
      t.datetime :trial_ends_at
      t.integer :billing_anchor
      t.datetime :renews_at
      t.datetime :ends_at
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean :test_mode

      # Don't define timestamps because LemonSqueeze already defines them
      # t.timestamps
    end
  end
end
