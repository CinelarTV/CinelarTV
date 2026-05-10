class AddGooglePlayFieldsToUserSubscriptions < ActiveRecord::Migration[6.0]
  def change
    add_column :user_subscriptions, :purchase_token, :string unless column_exists?(:user_subscriptions, :purchase_token)
    # Avoid clashing with existing integer `product_id` column used elsewhere.
    add_column :user_subscriptions, :google_product_id, :string unless column_exists?(:user_subscriptions, :google_product_id)
    add_column :user_subscriptions, :external_id, :string unless column_exists?(:user_subscriptions, :external_id)

    add_index :user_subscriptions, :purchase_token unless index_exists?(:user_subscriptions, :purchase_token)
    add_index :user_subscriptions, :external_id unless index_exists?(:user_subscriptions, :external_id)
  end
end
