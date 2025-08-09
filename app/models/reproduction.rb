class Reproduction < ApplicationRecord
  belongs_to :profile
  belongs_to :content

  validates :played_at, :country_code, presence: true

  def set_country_code(ip_address)
    raise ArgumentError, "No IP address provided" unless ip_address.present?

    if (ip_info = IpInfo.lookup(ip_address)) && ip_info[:country_code].present?
      self.country_code = ip_info[:country_code]
    end
  end

  scope :by_country, ->(code) { where(country_code: code) }

  def self.top_content_by_country(country_code, limit: 10)
  raise ArgumentError, "No country code provided" if country_code.blank?

  Content
    .joins("LEFT JOIN reproductions ON reproductions.content_id = contents.id AND reproductions.country_code = #{ActiveRecord::Base.connection.quote(country_code)}")
    .select('contents.*, COUNT(reproductions.id) AS reproduction_count')
    .group('contents.id')
    .order('reproduction_count DESC')
    .limit(limit)
rescue => e
  Rails.logger.error("Error fetching top #{limit} content for country #{country_code}: #{e.message}")
  []
end

end
