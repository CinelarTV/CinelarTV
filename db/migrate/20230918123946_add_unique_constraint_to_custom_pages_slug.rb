# frozen_string_literal: true

class AddUniqueConstraintToCustomPagesSlug < ActiveRecord::Migration[7.0]
  def change
    add_index :custom_pages, :slug, unique: true
  end
end
