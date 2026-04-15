# frozen_string_literal: true

require_relative "boot"
require "rails/all"

require "dotenv/load" if File.exist?(File.expand_path("../.env", __dir__))

Bundler.require(*Rails.groups)

module CinelarTV
  class Application < Rails::Application
    config.load_defaults 7.0

    config.autoload_paths << "#{root}/lib"
    config.autoload_paths << "#{root}/app/services"
    config.eager_load_paths << "#{root}/app/services"

    # Plugin paths
    %w[controllers models].each do |layer|
      Dir.glob(Rails.root.join("plugins", "*", "app", layer)).each do |dir|
        config.autoload_paths << dir
      end
    end

    Dir.glob(Rails.root.join("plugins", "*", "db", "migrate")).each do |dir|
      config.paths["db/migrate"] << dir.to_s
    end

    require "cinelar_tv"

    config.active_job.queue_adapter = :sidekiq

   
  end
end