# frozen_string_literal: true

class Reproduction < ApplicationRecord
  belongs_to :profile
  belongs_to :content
  # Otras relaciones...

  validates :played_at, presence: true
  validates :country_code, presence: true

  def set_country_code(ip_address = nil)
    raise "No IP address provided" unless ip_address

    ip_info = IpInfo.lookup(ip_address)
    self.country_code = ip_info[:country_code] if ip_info[:country_code].present?
  end

  def self.top_10_content_by_country(country_code)
    raise "No country code provided" unless country_code

    sql = <<-SQL
    SELECT contents.*, COUNT(reproductions.id) AS reproduction_count
    FROM contents
    LEFT JOIN reproductions ON contents.id = reproductions.content_id AND reproductions.country_code = '#{country_code}'
    GROUP BY contents.id
    ORDER BY reproduction_count DESC
    LIMIT 10
    SQL

    top_10_content = Content.find_by_sql(sql)

    return nil if top_10_content.count != 10
    top_10_content
  rescue StandardError => e
    Rails.logger.error("Error fetching top 10 content for country #{country_code}: #{e.message}")
    nil
  end
end
