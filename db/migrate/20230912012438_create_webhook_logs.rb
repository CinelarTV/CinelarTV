# frozen_string_literal: true

class CreateWebhookLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :webhook_logs do |t|
      t.string :event_name
      t.text :payload

      t.timestamps
    end
  end
end
