# frozen_string_literal: true

# config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end

if Rails.env.production? && ENV.keys.any? { |key| key.start_with?("RAILWAY_") }
  Rails.config.after_initialize do
    unless Sidekiq::ProcessSet.new.any? || !CinelarTV.maintenance_enabled
      Rails.logger.info("CinelarTV is running on Railway, starting Sidekiq manually...")
      system("bundle exec sidekiq")
    end
  end
end
