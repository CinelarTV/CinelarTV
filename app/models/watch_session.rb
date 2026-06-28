# frozen_string_literal: true

class WatchSession < ApplicationRecord
  belongs_to :profile
  belongs_to :content
  belongs_to :episode, optional: true

  validates :started_at, presence: true
  validates :duration_watched, numericality: { greater_than_or_equal_to: 0 }
  validates :total_duration, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(ended_at: nil) }
  scope :completed, -> { where(completed: true) }
  scope :by_date_range, ->(start_date, end_date) { where(started_at: start_date..end_date) }
  scope :by_content, ->(content_id) { where(content_id: content_id) }
  scope :by_profile, ->(profile_id) { where(profile_id: profile_id) }

  def end_session!
    update!(ended_at: Time.current) unless ended_at.present?
  end

  def watch_percentage
    return 0.0 if total_duration.zero?
    (duration_watched / total_duration * 100).round(1)
  end

  def mark_completed!
    return if completed?
    update!(completed: true, ended_at: ended_at || Time.current)
  end

  def self.end_stale_sessions!(timeout_seconds = 7200)
    active.where("updated_at < ?", timeout_seconds.seconds.ago).find_each do |session|
      session.end_session!
    end
  end
end
