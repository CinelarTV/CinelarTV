# frozen_string_literal: true

ruby "3.4.4"

# Bump this to issue a Rails update
rails_version = "7.2.0"

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "dotenv", groups: %i[development test]

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "actionmailer", rails_version
gem "actionpack", rails_version
gem "actionview", rails_version
gem "activemodel", rails_version
gem "activerecord", rails_version
gem "activesupport", rails_version
gem "rails", rails_version
gem "railties", rails_version

# Use Dart Sass for stylesheets
# gem "dartsass-rails"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

gem "csv"
gem "ostruct"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.0"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Dart Sass to process CSS (installed by dartsass-rails)

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "brakeman", "~> 5.1", require: false # A static analysis security vulnerability scanner for Ruby on Rails applications
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "factory_bot_rails"
  gem "faker"
  gem "rails-controller-testing"
  gem "rspec-rails", "~> 5.0"
  gem "rubocop", require: false # Automatic Ruby code style checking tool
  gem "rubocop-performance", require: false # A collection of RuboCop cops to check for performance optimizations in Ruby code
  gem "rubocop-rails", require: false # Automatic Rails code style checking tool
  gem "rubocop-rspec", require: false # Code style checking for RSpec files
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem "better_errors"
  gem "binding_of_caller"
  gem "listen", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end

gem "shakapacker", "= 8.0"

gem "rails-settings-cached", "~> 2.9"

gem "devise", "~> 4.9"

gem "devise_uid", "~> 0.1.1"

gem "rolify", "~> 6.0"

gem "message_bus"

# For multi-lingual app
gem "i18n-js", "~> 3"

gem "rack-mini-profiler", "~> 4.0"

gem "logster"

# Postgres on production
gem "pg", "~> 1.2"

gem "themoviedb-api", "~> 1.4"

gem "carrierwave", "~> 3.0"

gem "carrierwave-bombshelter", "~> 0.2.2"

gem "aws-sdk-s3", "~> 1"

gem "carrierwave-aws", "~> 1.6"

gem "erb-formatter", "~> 0.4.3"

gem "active_model_serializers", "~> 0.8.3"
gem "httparty"
gem "wdm", ">= 0.1.0", platforms: %i[mingw mswin x64_mingw jruby]

gem "sidekiq" # To run background jobs
# gem 'mini_scheduler' # To schedule background jobs
gem "sidekiq-scheduler"

gem "countries" # To get Countries information
gem "maxminddb" # To get user's location
gem "pry", "~> 0.14.2"
gem "pry-rails"

gem "doorkeeper"

# Enable the Device Authorization Grant flow
gem "doorkeeper-device_authorization_grant"
gem "doorkeeper-jwt"

#### Migration to Vite Rails ####
gem "vite_rails"

gem "js-routes", "~> 2.3"

# Use FFMPEG for video processing
gem "ffmpeg", git: "https://github.com/instructure/ruby-ffmpeg"
