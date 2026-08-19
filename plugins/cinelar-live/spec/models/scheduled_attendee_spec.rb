# frozen_string_literal: true

require "rails_helper"

RSpec.describe Live::ScheduledAttendee, type: :model do
  describe "validations" do
    it "prevents duplicate attendees for the same event" do
      event = create(:live_event)
      profile = create(:profile)

      create(:live_scheduled_attendee, live_event: event, profile: profile)
      duplicate = build(:live_scheduled_attendee, live_event: event, profile: profile)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:profile_id]).to include("has already been taken")
    end

    it "allows the same profile for different events" do
      event1 = create(:live_event)
      event2 = create(:live_event)
      profile = create(:profile)

      create(:live_scheduled_attendee, live_event: event1, profile: profile)
      attendee2 = build(:live_scheduled_attendee, live_event: event2, profile: profile)

      expect(attendee2).to be_valid
    end
  end
end
