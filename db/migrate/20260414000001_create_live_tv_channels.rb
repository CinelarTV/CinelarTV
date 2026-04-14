# frozen_string_literal: true

class CreateLiveTvChannels < ActiveRecord::Migration[7.2]
  def change
    create_table :live_tv_channels, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :logo_url
      t.string :stream_url, null: false
      t.string :stream_format, default: "hls", null: false
      t.boolean :is_active, default: true, null: false
      t.integer :position, default: 0
      t.string :xmltv_channel_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :is_active
      t.index :position
      t.index :xmltv_channel_id
    end
  end
end
