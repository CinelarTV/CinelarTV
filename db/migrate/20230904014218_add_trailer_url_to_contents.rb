# frozen_string_literal: true

class AddTrailerUrlToContents < ActiveRecord::Migration[7.0]
  def change
    add_column :contents, :trailer_url, :string
  end
end
