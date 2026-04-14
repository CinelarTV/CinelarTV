# frozen_string_literal: true

class CreateXmltvSources < ActiveRecord::Migration[7.2]
  def change
    create_table :xmltv_sources, id: :uuid do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.boolean :is_active, default: true, null: false
      t.datetime :last_fetched_at
      t.datetime :last_parsed_at
      t.text :raw_xml
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :url, unique: true
      t.index :is_active
    end
  end
end
