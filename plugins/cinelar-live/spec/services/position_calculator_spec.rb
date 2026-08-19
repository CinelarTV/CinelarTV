# frozen_string_literal: true

require "rails_helper"

RSpec.describe Live::PositionCalculator do
  describe ".current_position" do
    it "returns 0 when started_at is nil" do
      session = build(:watch_party_session, started_at: nil)
      expect(described_class.current_position(session)).to eq(0)
    end

    it "calculates position when playing" do
      session = build(
        :watch_party_session,
        started_at: 10.minutes.ago,
        playback_position: 0,
        is_playing: true,
        last_playback_update_at: 5.minutes.ago
      )

      position = described_class.current_position(session)
      expect(position).to be_within(1).of(300)
    end

    it "returns playback_position when not playing" do
      session = build(
        :watch_party_session,
        started_at: 10.minutes.ago,
        playback_position: 120.5,
        is_playing: false,
        last_playback_update_at: 5.minutes.ago
      )

      expect(described_class.current_position(session)).to eq(120.5)
    end
  end
end
