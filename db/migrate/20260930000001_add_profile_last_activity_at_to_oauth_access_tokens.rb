# frozen_string_literal: true

class AddProfileLastActivityAtToOauthAccessTokens < ActiveRecord::Migration[7.2]
  def up
    add_column :oauth_access_tokens, :profile_last_activity_at, :datetime

    # Tokens that already have a selected profile: seed activity from created_at
    # (oauth_access_tokens has no updated_at column)
    execute <<~SQL
      UPDATE oauth_access_tokens
      SET profile_last_activity_at = created_at
      WHERE current_profile_id IS NOT NULL
    SQL
  end

  def down
    remove_column :oauth_access_tokens, :profile_last_activity_at
  end
end
