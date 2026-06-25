class AddResizedImageUrlsToContents < ActiveRecord::Migration[7.2]
  def change
    add_column :contents, :banner_resized, :string
    add_column :contents, :cover_resized, :string
  end
end
