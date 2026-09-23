# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    create_table :audit_logs, id: :bigint do |t|
      t.references :user, type: :uuid, foreign_key: true, null: true
      t.integer :action, null: false
      t.string :custom_type, limit: 100
      t.string :auditable_type
      t.bigint :auditable_id
      t.references :target_user, type: :uuid, foreign_key: { to_table: :users }, null: true
      t.string :subject, limit: 255
      t.text :previous_value
      t.text :new_value
      t.text :details
      t.string :ip_address, limit: 45
      t.string :request_id, limit: 36
      t.string :context, limit: 500
      t.string :source, null: false, default: "core", limit: 100
      t.string :result, default: "success", limit: 20
      t.datetime :created_at, null: false
    end

    add_index :audit_logs, :created_at, algorithm: :concurrently
    add_index :audit_logs, :action, algorithm: :concurrently
    add_index :audit_logs, :custom_type, algorithm: :concurrently
    add_index :audit_logs, [:auditable_type, :auditable_id], name: "index_audit_logs_on_auditable", algorithm: :concurrently
    add_index :audit_logs, [:action, :created_at], algorithm: :concurrently
    add_index :audit_logs, :source, algorithm: :concurrently
  end

  def down
    drop_table :audit_logs
  end
end
