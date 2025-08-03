# frozen_string_literal: true
require "sidekiq-scheduler"

class Top10ContentJob
  include Sidekiq::Job

  def perform
    # Get a list of all country_code on Reproductions
    country_codes = Reproduction.distinct.pluck(:country_code)

    Rails.logger.info("Found #{country_codes.count} country codes on Reproductions.")

    # For each country_code, get the top 10 content
    country_codes.each do |country_code|
      top_10_content = Reproduction.top_10_content_by_country(country_code)

      if top_10_content.nil?
        Rails.logger.warn("No top 10 content found for country #{country_code}.")
        next
      end

      # Save the top 10 content on Redis
      CinelarTV.cache.write("top_10_content_#{country_code}", top_10_content)
      Rails.logger.info("Top 10 content for country #{country_code} saved on Redis, #{top_10_content.count} contents.")
    end
  end
end
