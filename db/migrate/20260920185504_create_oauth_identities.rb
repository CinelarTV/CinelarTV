# frozen_string_literal: true

class CreateOauthIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :oauth_identities, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :access_token
      t.string :refresh_token
      t.jsonb :extra_data, default: {}
      t.timestamps
    end
    add_index :oauth_identities, %i[provider uid], unique: true
  end
end
