# frozen_string_literal: true

module Live
  class Event < ApplicationRecord
    self.table_name = "live_events"

    belongs_to :content
    belongs_to :organizer, class_name: "User"
    has_many :attendees, class_name: "Live::ScheduledAttendee", foreign_key: :live_event_id, dependent: :destroy
    has_one :watch_party_session, class_name: "WatchParty::Session", foreign_key: :live_event_id
    has_many :chat_messages, class_name: "Live::ChatMessage", foreign_key: :live_event_id, dependent: :destroy

    enum :status, { scheduled: 0, starting: 1, live: 2, ended: 3, cancelled: 4 }

    validates :content, presence: true
    validates :starts_at, presence: true
    validate :content_must_be_movie
    validate :starts_at_must_be_future, on: :create

    scope :upcoming, -> { where(status: :scheduled).where("starts_at > ?", Time.current).order(:starts_at) }
    scope :active, -> { where(status: :live) }
    scope :public_events, -> { where(is_public: true) }

    def attendee_count
      attendees.count
    end

    def waiting?
      scheduled? && starts_at > Time.current
    end

    def can_accept_attendees?
      scheduled?
    end

    private

    def content_must_be_movie
      errors.add(:content, "must be a movie") if content.present? && content.content_type != "MOVIE"
    end

    def starts_at_must_be_future
      return if starts_at.blank?

      errors.add(:starts_at, "must be at least 5 minutes in the future") if starts_at <= 5.minutes.from_now
    end
  end
end
