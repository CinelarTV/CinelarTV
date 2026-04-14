# frozen_string_literal: true

class LiveTvChannel < ApplicationRecord
  has_many :tv_programs, dependent: :destroy

  validates :name, presence: true
  validates :stream_url, presence: true
  validates :stream_format, presence: true
  validates :stream_format, inclusion: { in: %w[hls dash rtmp external] }

  enum :stream_format, { hls: "hls", dash: "dash", rtmp: "rtmp", external: "external" }

  scope :active, -> { where(is_active: true).order(:position) }
  scope :inactive, -> { where(is_active: false) }

  def current_program
    tv_programs.where("start_time <= ? AND end_time >= ?", Time.current, Time.current)
               .order(start_time: :asc)
               .first
  end

  def upcoming_programs(limit = 5)
    tv_programs.where("start_time > ?", Time.current)
               .order(start_time: :asc)
               .limit(limit)
  end

  def current_or_next_program
    current_program || upcoming_programs(1).first
  end
end
