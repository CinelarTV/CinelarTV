# frozen_string_literal: true

class Reproduction < ApplicationRecord
  belongs_to :profile
  belongs_to :content

  validates :played_at, :country_code, presence: true

  scope :by_country, ->(code) { where(country_code: code) }

  def set_country_code(ip_address)
    raise ArgumentError, "No IP address provided" if ip_address.blank?

    ip_info = IpInfo.lookup(ip_address)
    self.country_code = ip_info[:country_code] if ip_info[:country_code].present?
  end

  def self.top_content_by_country(country_code, limit: 10)
    raise ArgumentError, "No country code provided" if country_code.blank?

    Content
      .joins("LEFT JOIN reproductions ON reproductions.content_id = contents.id AND reproductions.country_code = ?", country_code)
      .select("contents.*, COUNT(reproductions.id) AS reproduction_count")
      .group("contents.id")
      .order("reproduction_count DESC")
      .limit(limit)
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error("Error fetching top #{limit} content for country #{country_code}: #{e.message}")
    []
  end
end