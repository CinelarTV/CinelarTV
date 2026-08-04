# frozen_string_literal: true

class CreateBillingDomain < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :offering_key, null: false, default: "cinelartv_membership_monthly"
      t.string :status, null: false, default: "pending"
      t.string :provider_key, null: false
      t.string :provider_subscription_id
      t.string :provider_customer_id
      t.string :provider_plan_id
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, limit: 3
      t.string :interval_unit, null: false, default: "month"
      t.integer :interval_count, null: false, default: 1
      t.datetime :current_period_started_at
      t.datetime :current_period_ends_at
      t.datetime :access_until
      t.datetime :grace_ends_at
      t.boolean :cancel_at_period_end, null: false, default: false
      t.datetime :cancelled_at
      t.datetime :expired_at
      t.datetime :remote_updated_at
      t.datetime :last_reconciled_at
      t.jsonb :provider_metadata, null: false, default: {}
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :subscriptions, %i[provider_key provider_subscription_id], unique: true,
      where: "provider_subscription_id IS NOT NULL", name: "index_subscriptions_remote_id"
    add_index :subscriptions, :status
    add_index :subscriptions, :access_until
    add_index :subscriptions, :user_id, unique: true,
      where: "status IN ('pending', 'active', 'past_due', 'cancelled')", name: "index_one_open_subscription_per_user"

    create_table :payments, id: :uuid do |t|
      t.references :subscription, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :provider_key, null: false
      t.string :provider_invoice_id
      t.string :provider_payment_id
      t.string :kind, null: false, default: "renewal"
      t.string :status, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, limit: 3
      t.datetime :attempted_at
      t.datetime :paid_at
      t.string :failure_code
      t.text :failure_message
      t.jsonb :provider_metadata, null: false, default: {}
      t.timestamps
    end
    add_index :payments, %i[provider_key provider_payment_id], unique: true,
      where: "provider_payment_id IS NOT NULL", name: "index_payments_remote_payment_id"
    add_index :payments, %i[provider_key provider_invoice_id], unique: true,
      where: "provider_invoice_id IS NOT NULL", name: "index_payments_remote_invoice_id"

    create_table :provider_events, id: :uuid do |t|
      t.string :provider_key, null: false
      t.string :provider_event_id
      t.string :event_type, null: false
      t.string :resource_type
      t.string :resource_id
      t.boolean :signature_valid, null: false
      t.datetime :occurred_at
      t.datetime :received_at, null: false
      t.datetime :processed_at
      t.text :processing_error
      t.integer :attempt_count, null: false, default: 0
      t.string :payload_sha256, null: false
      t.jsonb :payload, null: false, default: {}
      t.jsonb :headers, null: false, default: {}
      t.timestamps
    end
    add_index :provider_events, %i[provider_key provider_event_id], unique: true,
      where: "provider_event_id IS NOT NULL", name: "index_provider_events_external_id"
    add_index :provider_events, %i[provider_key event_type resource_id payload_sha256], unique: true,
      name: "index_provider_events_dedup_fallback"

    create_table :subscription_access_grants, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :granted_by_user, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :reason, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :subscription_access_grants, %i[user_id starts_at ends_at], name: "index_access_grants_active_lookup"
  end
end
