# frozen_string_literal: true

class AddCurrentProfileIdToOauthAccessTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :oauth_access_tokens, :current_profile_id, :uuid, null: true
  end
end
