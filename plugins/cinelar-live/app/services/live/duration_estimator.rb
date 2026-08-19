# frozen_string_literal: true

module Live
  class DurationEstimator
    MIN_VALID = 60
    MAX_VALID = 43_200
    LOW_CONFIDENCE_THRESHOLD = 3
    RELIABLE_THRESHOLD = 10

    def self.estimate(content_id)
      durations = ContinueWatching
        .where(content_id: content_id, episode_id: nil)
        .where("duration > ? AND duration < ?", MIN_VALID, MAX_VALID)
        .pluck(:duration)

      return { duration: nil, confidence: :unknown, sample_size: 0 } if durations.empty?
      return { duration: nil, confidence: :low, sample_size: durations.size } if durations.size < LOW_CONFIDENCE_THRESHOLD

      median = durations.sort[durations.size / 2]
      confidence = durations.size >= RELIABLE_THRESHOLD ? :reliable : :estimated

      { duration: median, confidence: confidence, sample_size: durations.size }
    end
  end
end
