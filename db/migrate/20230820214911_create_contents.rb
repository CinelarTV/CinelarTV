# frozen_string_literal: true

class CreateContents < ActiveRecord::Migration[7.0]
  def change
    create_table :contents, id: :uuid do |t|
      t.string :title
      t.string :description
      t.string :banner
      t.string :cover
      t.string :content_type
      t.string :url
      t.integer :year

      t.timestamps
    end
  end
end
