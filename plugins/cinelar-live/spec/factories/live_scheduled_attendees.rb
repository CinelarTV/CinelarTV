# frozen_string_literal: true

FactoryBot.define do
  factory :live_scheduled_attendee, class: "Live::ScheduledAttendee" do
    association :live_event, factory: :live_event
    association :profile
  end
end
