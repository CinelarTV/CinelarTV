# frozen_string_literal: true

class AddUniqueIndexToContentAnalyticsContentId < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    remove_index :content_analytics, :content_id if index_exists?(:content_analytics, :content_id)
    add_index :content_analytics, :content_id, unique: true
  end
end
