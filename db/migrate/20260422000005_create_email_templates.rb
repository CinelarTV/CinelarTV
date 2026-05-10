# frozen_string_literal: true

class CreateEmailTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :email_templates do |t|
      t.string :key, null: false
      t.string :locale, null: false
      t.text :subject
      t.text :body
      t.jsonb :interpolation_variables, default: []

      t.timestamps
    end

    add_index :email_templates, [:key, :locale], unique: true
    add_index :email_templates, :key
    add_index :email_templates, :locale
  end
end
