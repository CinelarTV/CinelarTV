# frozen_string_literal: true

require "rails_helper"

RSpec.describe Live::DurationEstimator do
  describe ".estimate" do
    it "returns unknown when no data exists" do
      content = create(:content, content_type: "MOVIE")
      result = described_class.estimate(content.id)

      expect(result[:confidence]).to eq(:unknown)
      expect(result[:duration]).to be_nil
    end

    it "returns low confidence with fewer than 3 samples" do
      content = create(:content, content_type: "MOVIE")
      create(:continue_watchings, content: content, duration: 7200)

      result = described_class.estimate(content.id)
      expect(result[:confidence]).to eq(:low)
      expect(result[:sample_size]).to eq(1)
    end

    it "returns estimated confidence with 3-9 samples" do
      content = create(:content, content_type: "MOVIE")
      5.times { create(:continue_watchings, content: content, duration: 7200) }

      result = described_class.estimate(content.id)
      expect(result[:confidence]).to eq(:estimated)
      expect(result[:sample_size]).to eq(5)
    end

    it "returns reliable confidence with 10+ samples" do
      content = create(:content, content_type: "MOVIE")
      12.times { create(:continue_watchings, content: content, duration: 7200) }

      result = described_class.estimate(content.id)
      expect(result[:confidence]).to eq(:reliable)
      expect(result[:sample_size]).to eq(12)
    end

    it "discards outliers below minimum" do
      content = create(:content, content_type: "MOVIE")
      create(:continue_watchings, content: content, duration: 30)  # invalid
      create(:continue_watchings, content: content, duration: 7200)
      create(:continue_watchings, content: content, duration: 7200)

      result = described_class.estimate(content.id)
      expect(result[:sample_size]).to eq(2)  # 30s excluded
    end

    it "uses median for estimate" do
      content = create(:content, content_type: "MOVIE")
      durations = [6000, 7200, 7200, 7200, 8400]
      durations.each { |d| create(:continue_watchings, content: content, duration: d) }

      result = described_class.estimate(content.id)
      expect(result[:duration]).to eq(7200)
    end
  end
end
