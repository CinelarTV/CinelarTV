# frozen_string_literal: true

module WatchParty
  class SessionUser < ApplicationRecord
    self.table_name = "watch_party_session_users"

    belongs_to :watch_party_session, class_name: "WatchParty::Session", foreign_key: "watch_party_session_id"
    belongs_to :user, foreign_key: "user_id"
  end
end
