# frozen_string_literal: true

class CreateVideoSources < ActiveRecord::Migration[7.0]
  def change
    create_table :video_sources do |t|
      t.string :url
      t.string :quality
      t.string :format
      t.string :storage_location
      t.references :videoable, polymorphic: true, null: false, type: :uuid

      t.timestamps
    end
  end
end
