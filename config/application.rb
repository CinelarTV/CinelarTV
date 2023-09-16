# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CinelarTV
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    if Rails.env.production? && ENV.keys.any? { |key| key.start_with?("RAILWAY_") }
      config.after_initialize do
        unless Sidekiq::ProcessSet.new.any? || !CinelarTV.maintenance_enabled
          Rails.logger.info("CinelarTV is running on Railway, starting Sidekiq manually...")
          system("bundle exec sidekiq")
        end
      end
    end

    lib_dir = Rails.root.join("lib")

    config.autoload_paths << "#{root}/lib"

    require "cinelar_tv"

    config.active_job.queue_adapter = :sidekiq
  end
end
