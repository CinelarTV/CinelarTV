# frozen_string_literal: true

class RemoveUrlFromContentsAndEpisodes < ActiveRecord::Migration[7.2]
  def change
    remove_column :contents, :url, :string
    remove_column :episodes, :url, :string
  end
end
