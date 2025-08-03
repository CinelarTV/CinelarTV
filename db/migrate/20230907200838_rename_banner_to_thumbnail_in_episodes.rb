# frozen_string_literal: true

class RenameBannerToThumbnailInEpisodes < ActiveRecord::Migration[7.0]
  def change
    rename_column :episodes, :banner, :thumbnail
  end
end
