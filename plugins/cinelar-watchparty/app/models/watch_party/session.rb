# frozen_string_literal: true

module WatchParty
  class Session < ApplicationRecord
    self.table_name = "watch_party_sessions"

    belongs_to :host, class_name: "User", optional: true
    belongs_to :content, optional: true

    has_many :session_users, class_name: "WatchParty::SessionUser", foreign_key: "watch_party_session_id", dependent: :destroy
    has_many :users, through: :session_users, source: :user

    scope :active, -> { where(ended_at: nil) }
  end
end
