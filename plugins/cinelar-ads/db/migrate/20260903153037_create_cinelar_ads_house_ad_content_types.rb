# frozen_string_literal: true

class CreateCinelarAdsHouseAdContentTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :cinelar_ads_house_ad_content_types, id: :bigint do |t|
      t.references :house_ad, null: false, foreign_key: { to_table: :cinelar_ads_house_ads }, type: :bigint
      t.string :content_type, null: false
      t.timestamps
    end

    add_index :cinelar_ads_house_ad_content_types, [:house_ad_id, :content_type], unique: true, name: "idx_cinelar_ads_ha_ct_unique"
  end
end
