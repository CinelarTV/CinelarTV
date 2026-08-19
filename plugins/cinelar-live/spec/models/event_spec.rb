# frozen_string_literal: true

require "rails_helper"

RSpec.describe Live::Event, type: :model do
  describe "validations" do
    it "requires content" do
      event = build(:live_event, content: nil)
      expect(event).not_to be_valid
      expect(event.errors[:content]).to include("can't be blank")
    end

    it "requires starts_at" do
      event = build(:live_event, starts_at: nil)
      expect(event).not_to be_valid
      expect(event.errors[:starts_at]).to include("can't be blank")
    end

    it "validates content is a MOVIE" do
      movie = create(:content, content_type: "MOVIE")
      tvshow = create(:content, content_type: "TVSHOW")

      event_movie = build(:live_event, content: movie)
      expect(event_movie).to be_valid

      event_tvshow = build(:live_event, content: tvshow)
      expect(event_tvshow).not_to be_valid
      expect(event_tvshow.errors[:content]).to include("must be a movie")
    end
  end

  describe "scopes" do
    it ".upcoming returns scheduled events in the future" do
      upcoming = create(:live_event, starts_at: 1.hour.from_now)
      past = create(:live_event, starts_at: 1.hour.ago, status: :ended)

      expect(Live::Event.upcoming).to include(upcoming)
      expect(Live::Event.upcoming).not_to include(past)
    end

    it ".active returns live events" do
      live = create(:live_event, status: :live)
      scheduled = create(:live_event, status: :scheduled)

      expect(Live::Event.active).to include(live)
      expect(Live::Event.active).not_to include(scheduled)
    end
  end

  describe "#waiting?" do
    it "returns true when scheduled and starts_at is in the future" do
      event = build(:live_event, status: :scheduled, starts_at: 1.hour.from_now)
      expect(event.waiting?).to be true
    end

    it "returns false when live" do
      event = build(:live_event, status: :live, starts_at: 1.hour.ago)
      expect(event.waiting?).to be false
    end
  end

  describe "#can_accept_attendees?" do
    it "returns true when scheduled" do
      event = build(:live_event, status: :scheduled)
      expect(event.can_accept_attendees?).to be true
    end

    it "returns false when live" do
      event = build(:live_event, status: :live)
      expect(event.can_accept_attendees?).to be false
    end
  end
end
