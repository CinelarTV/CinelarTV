# frozen_string_literal: true

class AddBannerToEpisodes < ActiveRecord::Migration[7.0]
  def change
    add_column :episodes, :banner, :string
  end
end
