# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WatchSession, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:started_at) }
    it { should validate_numericality_of(:duration_watched).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:total_duration).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { should belong_to(:profile) }
    it { should belong_to(:content) }
    it { should belong_to(:episode).optional }
  end

  describe 'scopes' do
    let!(:active_session) { create(:watch_session, :active) }
    let!(:completed_session) { create(:watch_session, :completed) }

    it 'returns active sessions' do
      expect(WatchSession.active).to include(active_session)
      expect(WatchSession.active).not_to include(completed_session)
    end

    it 'returns completed sessions' do
      expect(WatchSession.completed).to include(completed_session)
      expect(WatchSession.completed).not_to include(active_session)
    end
  end

  describe '#end_session!' do
    it 'sets ended_at to current time' do
      session = create(:watch_session, :active)
      session.end_session!
      expect(session.ended_at).not_to be_nil
    end

    it 'does not change ended_at if already set' do
      session = create(:watch_session, :completed)
      original_ended_at = session.ended_at
      session.end_session!
      expect(session.ended_at).to eq(original_ended_at)
    end
  end

  describe '#watch_percentage' do
    it 'calculates watch percentage correctly' do
      session = build(:watch_session, duration_watched: 1800, total_duration: 3600)
      expect(session.watch_percentage).to eq(50.0)
    end

    it 'returns 0.0 when total_duration is 0' do
      session = build(:watch_session, duration_watched: 0, total_duration: 0)
      expect(session.watch_percentage).to eq(0.0)
    end
  end

  describe '#mark_completed!' do
    it 'marks session as completed' do
      session = create(:watch_session, :active)
      session.mark_completed!
      expect(session.completed).to be true
      expect(session.ended_at).not_to be_nil
    end
  end

  describe '.end_stale_sessions!' do
    it 'ends sessions older than timeout' do
      stale_session = create(:watch_session, :active, updated_at: 3.hours.ago)
      recent_session = create(:watch_session, :active, updated_at: 1.hour.ago)

      WatchSession.end_stale_sessions!(7200)

      expect(stale_session.reload.ended_at).not_to be_nil
      expect(recent_session.reload.ended_at).to be_nil
    end
  end
end
