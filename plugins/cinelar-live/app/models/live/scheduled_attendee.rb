# frozen_string_literal: true

module Live
  class ScheduledAttendee < ApplicationRecord
    self.table_name = "live_event_attendees"

    belongs_to :live_event, class_name: "Live::Event"
    belongs_to :profile

    validates :profile_id, uniqueness: { scope: :live_event_id }
  end
end
