# frozen_string_literal: true

class Reproduction < ApplicationRecord
  belongs_to :profile
  belongs_to :content

  validates :played_at, :country_code, presence: true

  scope :by_country, ->(code) { where(country_code: code) }

  REPRODUCTION_WINDOW = 30.days

  def set_country_code(ip_address)
    raise ArgumentError, "No IP address provided" if ip_address.blank?

    ip_info = IpInfo.lookup(ip_address)
    self.country_code = ip_info[:country_code] if ip_info[:country_code].present?
  end

  def self.top_content_by_country(country_code, limit: 10)
    raise ArgumentError, "No country code provided" if country_code.blank?

    quoted_country = connection.quote(country_code)
    quoted_window = connection.quote(REPRODUCTION_WINDOW.ago)

    Content
      .available
      .left_joins(:content_analytic)
      .joins(<<~SQL.squish)
        INNER JOIN reproductions r ON r.content_id = contents.id
          AND r.country_code = #{quoted_country}
          AND r.played_at >= #{quoted_window}
      SQL
      .joins(<<~SQL.squish)
        LEFT JOIN likes l ON l.content_id = contents.id
      SQL
      .group("contents.id, content_analytics.id")
      .select(<<~SQL.squish)
        contents.*,
        COUNT(DISTINCT r.id) AS reproduction_count,
        COUNT(DISTINCT r.profile_id) AS unique_viewers,
        COUNT(DISTINCT l.id) AS likes_count,
        COALESCE(content_analytics.completion_rate, 0) AS completion_rate,
        COALESCE(content_analytics.unique_profiles, 0) AS global_unique_profiles,
        MAX(r.played_at) AS last_played_at
      SQL
      .order(Arel.sql(<<~SQL.squish))
        (COUNT(DISTINCT r.profile_id) * 3.0
         + COUNT(DISTINCT r.id) * 1.0
         + COUNT(DISTINCT l.id) * 2.0
         + COALESCE(content_analytics.completion_rate, 0) * 0.05)
         * (1.0 / (1.0 + GREATEST(EXTRACT(EPOCH FROM (NOW() - MAX(r.played_at))) / 604800.0, 0)))
         DESC
      SQL
      .limit(limit)
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error("Error fetching top #{limit} content for country #{country_code}: #{e.message}")
    []
  end
end
