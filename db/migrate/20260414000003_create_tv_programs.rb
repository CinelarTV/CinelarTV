# frozen_string_literal: true

class CreateTvPrograms < ActiveRecord::Migration[7.2]
  def change
    create_table :tv_programs, id: :uuid do |t|
      t.uuid :live_tv_channel_id, null: false
      t.string :title, null: false
      t.text :description
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :icon_url
      t.string :category
      t.string :xmltv_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :live_tv_channel_id
      t.index :start_time
      t.index :end_time
      t.index [:live_tv_channel_id, :start_time, :end_time], name: "index_tv_programs_on_channel_and_times"
    end

    add_foreign_key :tv_programs, :live_tv_channels
  end
end
