# frozen_string_literal: true

require "rails_helper"

RSpec.describe Live::StartScheduledEventsJob do
  describe "#perform" do
    it "starts events whose starts_at has passed" do
      event = create(:live_event, status: :scheduled, starts_at: 1.minute.ago)

      described_class.new.perform

      event.reload
      expect(event.status).to eq("live")
      expect(event.watch_party_session).to be_present
    end

    it "does not start future events" do
      event = create(:live_event, status: :scheduled, starts_at: 1.hour.from_now)

      described_class.new.perform

      event.reload
      expect(event.status).to eq("scheduled")
    end

    it "creates a WatchParty::Session with is_public true" do
      event = create(:live_event, status: :scheduled, starts_at: 1.minute.ago)

      described_class.new.perform

      session = event.watch_party_session
      expect(session).to be_present
      expect(session.is_public).to be true
      expect(session.live_event_id).to eq(event.id)
      expect(session.is_playing).to be true
    end

    it "cancels event if creation fails" do
      event = create(:live_event, status: :scheduled, starts_at: 1.minute.ago)
      allow(WatchParty::Session).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      described_class.new.perform

      event.reload
      expect(event.status).to eq("cancelled")
    end
  end
end
