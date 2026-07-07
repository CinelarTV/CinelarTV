# frozen_string_literal: true

class TvProgram < ApplicationRecord
  belongs_to :live_tv_channel

  validates :title, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  scope :currently_playing, -> { where("start_time <= ? AND end_time > ?", Time.current, Time.current) }
  scope :upcoming, -> { where("start_time > ?", Time.current).order(:start_time) }
  scope :past, -> { where("end_time < ?", Time.current).order(start_time: :desc) }
  scope :for_time_range, ->(start_time, end_time) {
    where("start_time < ? AND end_time > ?", end_time, start_time).order(:start_time)
  }

  def currently_playing?
    Time.current >= start_time && Time.current < end_time
  end

  def upcoming?
    start_time > Time.current
  end

  def past?
    end_time < Time.current
  end

  def duration
    return nil unless start_time && end_time

    (end_time - start_time).to_i
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time
    return if end_time > start_time

    errors.add(:end_time, "must be after start time")
  end
end
