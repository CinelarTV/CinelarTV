# frozen_string_literal: true

class EnhanceBackupsForFullSystem < ActiveRecord::Migration[7.2]
  def change
    change_table :backups do |t|
      t.string :status, default: "pending", null: false
      t.string :checksum
      t.boolean :encrypted, default: false, null: false
      t.text :encryption_key_fingerprint
      t.jsonb :file_manifest, default: {}
      t.jsonb :audit_log, default: []
      t.datetime :completed_at
      t.datetime :expires_at
      t.integer :retention_days, default: 30
      t.string :error_message
    end

    add_index :backups, :status
    add_index :backups, :created_at
    add_index :backups, :expires_at
  end
end
