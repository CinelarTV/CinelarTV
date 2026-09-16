# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentSearchService do
  describe "#execute" do
    let!(:movie) do
      Content.create!(
        title: "Cuento de una noche",
        description: "Una historia mágica sobre los sueños y la fantasía",
        content_type: "MOVIE",
        year: 2023,
        available: true
      )
    end

    let!(:other_movie) do
      Content.create!(
        title: "Solo en casa",
        description: "Un clásico navideño inolvidable",
        content_type: "MOVIE",
        year: 1990,
        available: true
      )
    end

    before do
      # Ensure search_data is populated for both records
      movie.update_search_data
      other_movie.update_search_data
    end

    it "returns empty result when query is shorter than 2 characters" do
      result = described_class.new(term: "c").execute
      expect(result[:contents]).to be_empty
    end

    it "matches on partial word prefix 'Cue'" do
      result = described_class.new(term: "Cue").execute
      expect(result[:contents]).to include(movie)
      expect(result[:contents]).not_to include(other_movie)
    end

    it "matches on partial word prefix 'Cuen'" do
      result = described_class.new(term: "Cuen").execute
      expect(result[:contents]).to include(movie)
      expect(result[:contents]).not_to include(other_movie)
    end

    it "matches on full word 'Cuento'" do
      result = described_class.new(term: "Cuento").execute
      expect(result[:contents]).to include(movie)
      expect(result[:contents]).not_to include(other_movie)
    end

    it "matches on multi-word with prefix 'Cuento d'" do
      result = described_class.new(term: "Cuento d").execute
      expect(result[:contents]).to include(movie)
      expect(result[:contents]).not_to include(other_movie)
    end

    it "matches on complete title 'Cuento de una noche'" do
      result = described_class.new(term: "Cuento de una noche").execute
      expect(result[:contents]).to include(movie)
    end

    it "matches words in description" do
      result = described_class.new(term: "fantas").execute
      expect(result[:contents]).to include(movie)
    end

    it "matches with accents or without accents" do
      result_with_accent = described_class.new(term: "mágica").execute
      result_without_accent = described_class.new(term: "magica").execute

      expect(result_with_accent[:contents]).to include(movie)
      expect(result_without_accent[:contents]).to include(movie)
    end

    it "filters by type" do
      result = described_class.new(term: "Cuento type:movie").execute
      expect(result[:contents]).to include(movie)

      result_series = described_class.new(term: "Cuento type:series").execute
      expect(result_series[:contents]).to be_empty
    end

    it "filters by year" do
      result = described_class.new(term: "Cuento year:2023").execute
      expect(result[:contents]).to include(movie)

      result_wrong_year = described_class.new(term: "Cuento year:2020").execute
      expect(result_wrong_year[:contents]).to be_empty
    end
  end
end
