# frozen_string_literal: true

class RefactorUserSubscriptionsForModularProviders < ActiveRecord::Migration[7.2]
  def change
    change_table :user_subscriptions, bulk: true do |t|
      t.string :provider, null: false, default: "mercado_pago"
      t.string :provider_subscription_id
      t.string :provider_customer_id
      t.string :provider_plan_id
      t.string :checkout_reference
      t.string :external_status
      t.boolean :granted_by_admin, null: false, default: false
      t.datetime :granted_until
      t.datetime :cancelled_at
      t.jsonb :metadata, null: false, default: {}
    end

    add_index :user_subscriptions, :provider
    add_index :user_subscriptions, %i[provider provider_subscription_id], unique: true, where: "provider_subscription_id IS NOT NULL", name: "idx_user_subscriptions_provider_external_id"
  end
end
