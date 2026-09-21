# frozen_string_literal: true

class CreateCinelarAdsHouseAdSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :cinelar_ads_house_ad_settings, id: :bigint do |t|
      t.string :slot, null: false
      t.text :ad_names, null: false
      t.timestamps
    end

    add_index :cinelar_ads_house_ad_settings, :slot, unique: true
  end
end
