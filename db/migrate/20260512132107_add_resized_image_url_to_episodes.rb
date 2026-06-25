class AddResizedImageUrlToEpisodes < ActiveRecord::Migration[7.2]
  def change
    add_column :episodes, :thumbnail_resized, :string
  end
end
