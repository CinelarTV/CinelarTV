class CreateSubscriptionPayments < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_payments, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :user_subscription, null: false, foreign_key: true, type: :bigint
      t.string :provider, null: false
      t.string :provider_payment_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false
      t.string :status, null: false
      t.datetime :paid_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :subscription_payments, [:provider, :provider_payment_id], unique: true
  end
end
