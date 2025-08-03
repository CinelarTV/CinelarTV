# frozen_string_literal: true

require_relative "boot"
require "pry"

require "rails/all"


# Load dotenv to manage environment variables
require "dotenv/load" if File.exist?(File.expand_path("../.env", __dir__))

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

    Rails.root.join("lib")

    config.autoload_paths << "#{root}/lib"

    require "cinelar_tv"

    config.active_job.queue_adapter = :sidekiq

    # Print .env for debugging purposes
    if Rails.env.development? || Rails.env.test?
      puts "CINELAR_DB: #{ENV['CINELAR_DB']}"
      puts "CINELAR_DB_HOSTNAME: #{ENV['CINELAR_DB_HOSTNAME']}"
      puts "CINELAR_DB_USERNAME: #{ENV['CINELAR_DB_USERNAME']}"
      puts "CINELAR_DB_PASSWORD: #{ENV['CINELAR_DB_PASSWORD']}"
      puts "CINELAR_DB_PORT: #{ENV['CINELAR_DB_PORT']}"
    end
  end
end
