# frozen_string_literal: true

class CreateLiveChatMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :live_chat_messages, id: :bigint do |t|
      t.references :live_event, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true, type: :uuid
      t.string :message_type, null: false, default: "user"
      t.text :body
      t.boolean :deleted, null: false, default: false
      t.datetime :deleted_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :live_chat_messages, [:live_event_id, :created_at]
    add_index :live_chat_messages, :message_type
  end
end
