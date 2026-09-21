# frozen_string_literal: true

class CreateCinelarAdsHouseAdCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :cinelar_ads_house_ad_categories, id: :bigint do |t|
      t.references :house_ad, null: false, foreign_key: { to_table: :cinelar_ads_house_ads }, type: :bigint
      t.references :category, null: false, foreign_key: true, type: :bigint
      t.timestamps
    end

    add_index :cinelar_ads_house_ad_categories, [:house_ad_id, :category_id], unique: true, name: "idx_cinelar_ads_ha_cat_unique"
  end
end
