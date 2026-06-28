# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentAnalytic, type: :model do
  describe 'associations' do
    it { should belong_to(:content) }
  end

  describe '.recalculate!' do
    let!(:content) { create(:content) }
    let!(:profile) { create(:profile) }

    context 'with watch sessions' do
      before do
        create(:watch_session, content: content, profile: profile, duration_watched: 3600, total_duration: 3600, completed: true)
        create(:watch_session, content: content, profile: profile, duration_watched: 1800, total_duration: 3600, completed: false)
      end

      it 'creates content analytic' do
        expect {
          ContentAnalytic.recalculate!(content)
        }.to change(ContentAnalytic, :count).by(1)
      end

      it 'calculates correct metrics' do
        ContentAnalytic.recalculate!(content)
        analytics = content.content_analytic

        expect(analytics.total_views).to eq(2)
        expect(analytics.total_seconds_watched).to eq(5400)
        expect(analytics.unique_profiles).to eq(1)
        expect(analytics.completion_rate).to eq(50.0)
      end
    end

    context 'without watch sessions' do
      it 'does not create content analytic' do
        expect {
          ContentAnalytic.recalculate!(content)
        }.not_to change(ContentAnalytic, :count)
      end
    end
  end

  describe '#total_hours_watched' do
    let!(:analytics) { create(:content_analytic, total_seconds_watched: 7200) }

    it 'converts seconds to hours' do
      expect(analytics.total_hours_watched).to eq(2.0)
    end
  end
end
