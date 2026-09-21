# frozen_string_literal: true

class CreateCinelarAdsHouseAds < ActiveRecord::Migration[7.2]
  def change
    create_table :cinelar_ads_house_ads, id: :bigint do |t|
      t.string :name, null: false
      t.text :html, null: false
      t.boolean :visible_to_anons, default: true, null: false
      t.boolean :visible_to_logged_in_users, default: true, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :cinelar_ads_house_ads, :name, unique: true
  end
end
