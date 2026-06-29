class RenameGoogleProductIdToIapProductId < ActiveRecord::Migration[7.2]
  def change
    rename_column :user_subscriptions, :google_product_id, :iap_product_id
  end
end
