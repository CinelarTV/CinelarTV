# frozen_string_literal: true

class Segment < ApplicationRecord
  belongs_to :segmentable, polymorphic: true

  enum segment_type: {
    skip_intro: 'skip_intro',
    skip_resume: 'skip_resume',
    next_episode: 'next_episode',
    credits_start: 'credits_start'
  }

  validates :segment_type, presence: true
  validates :segmentable, presence: true

  # For point-only segments (next_episode, credits_start), end_time should be nil
  validate :end_time_nil_for_point_segments

  # For range segments (skip_intro, skip_resume), both times should be present
  validate :times_present_for_range_segments

  # Ensure start_time is before end_time for range segments
  validate :start_before_end

  private

  def end_time_nil_for_point_segments
    return unless next_episode? || credits_start?

    if end_time.present?
      errors.add(:end_time, "must be nil for point segments")
    end
  end

  def times_present_for_range_segments
    return if next_episode? || credits_start?

    if start_time.blank? || end_time.blank?
      errors.add(:base, "Both start_time and end_time are required for range segments")
    end
  end

  def start_before_end
    return if next_episode? || credits_start?
    return if start_time.blank? || end_time.blank?

    if start_time >= end_time
      errors.add(:start_time, "must be before end_time")
    end
  end
end
