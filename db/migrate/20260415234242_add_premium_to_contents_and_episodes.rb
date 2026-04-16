class AddPremiumToContentsAndEpisodes < ActiveRecord::Migration[7.2]
  def change
    add_column :contents, :premium, :boolean, default: false
    add_column :episodes, :premium, :boolean, default: false
  end
end
