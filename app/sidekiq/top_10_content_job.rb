# frozen_string_literal: true
require "sidekiq-scheduler"

class Top10ContentJob
  include Sidekiq::Job

  def perform
    country_codes = Reproduction.distinct.pluck(:country_code)

    Rails.logger.info("Found #{country_codes.count} country codes on Reproductions.")

    country_codes.each do |country_code|
      top_10_content = Reproduction.top_content_by_country(country_code)

      if top_10_content.blank?
        Rails.logger.warn("No top 10 content found for country #{country_code}.")
        next
      end

      # Convertir a array serializable antes de cachear
      serialized = top_10_content.as_json(only: %i[id title description banner banner_resized cover_resized content_type year])
      CinelarTV.cache.write("top_10_content_#{country_code}", serialized)
      Rails.logger.info("Top 10 content for country #{country_code} saved on Redis, #{serialized.size} contents.")
    end
  end
end
