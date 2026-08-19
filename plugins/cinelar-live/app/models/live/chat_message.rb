# frozen_string_literal: true

module Live
  class ChatMessage < ApplicationRecord
    self.table_name = "live_chat_messages"

    belongs_to :live_event, class_name: "Live::Event"
    belongs_to :profile

    validates :message_type, inclusion: { in: %w[user system] }
    validates :body, presence: true, if: -> { message_type == "user" }
    validates :profile, presence: true

    scope :visible, -> { where(deleted: false) }
    scope :recent, ->(limit = 100) { visible.order(created_at: :desc).limit(limit) }

    def system?
      message_type == "system"
    end

    def soft_delete!
      update!(deleted: true, deleted_at: Time.current)
    end
  end
end
