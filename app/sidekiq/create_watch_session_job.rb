# frozen_string_literal: true

class CreateWatchSessionJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  def perform(profile_id, content_id, episode_id, ip_address)
    country_code = nil
    if ip_address.present?
      ip_info = IpInfo.lookup(ip_address)
      country_code = ip_info[:country_code] if ip_info[:country_code].present?
    end

    WatchSession.create!(
      profile_id: profile_id,
      content_id: content_id,
      episode_id: episode_id,
      started_at: Time.current,
      duration_watched: 0,
      total_duration: 0,
      completed: false,
      country_code: country_code
    )
  rescue StandardError => e
    Rails.logger.error "Error creating watch session: #{e.message}"
  end
end
