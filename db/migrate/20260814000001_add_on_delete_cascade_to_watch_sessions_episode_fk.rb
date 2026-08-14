# frozen_string_literal: true

class AddOnDeleteCascadeToWatchSessionsEpisodeFk < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :watch_sessions, :episodes
    add_foreign_key :watch_sessions, :episodes, on_delete: :cascade
  end
end
