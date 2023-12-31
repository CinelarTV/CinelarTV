# frozen_string_literal: true

class CreateSettings < ActiveRecord::Migration[7.0]
  def self.up
    create_table :settings do |t|
      t.string  :var,        null: false
      t.text    :value,      null: true
      t.string  :data_type,  null: false, default: 'string'
      t.timestamps
    end

    add_index :settings, %i[var], unique: true
  end

  def self.down
    drop_table :settings
  end
end
