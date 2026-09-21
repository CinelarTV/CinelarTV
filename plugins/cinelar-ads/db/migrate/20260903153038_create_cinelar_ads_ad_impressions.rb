# frozen_string_literal: true

class CreateCinelarAdsAdImpressions < ActiveRecord::Migration[7.2]
  def change
    create_table :cinelar_ads_ad_impressions, id: :bigint do |t|
      t.string :ad_type, null: false
      t.string :placement, null: false
      t.references :house_ad, foreign_key: { to_table: :cinelar_ads_house_ads }, type: :bigint
      t.references :user, foreign_key: true, type: :uuid
      t.string :ip_address
      t.datetime :clicked_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :cinelar_ads_ad_impressions, :ad_type
    add_index :cinelar_ads_ad_impressions, :placement
    add_index :cinelar_ads_ad_impressions, :created_at
    add_index :cinelar_ads_ad_impressions, [:ad_type, :placement]
  end
end
