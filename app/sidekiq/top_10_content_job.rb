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
      serialized = top_10_content.map do |content|
        {
          id: content.id,
          title: content.title,
          description: content.description,
          content_type: content.content_type,
          year: content.year,
          banner: content.image_url_for("backdrop"),
          poster: content.image_url_for("poster"),
          banner_resized: content.image_url_for("backdrop", variant: "medium"),
          cover_resized: content.image_url_for("poster", variant: "medium"),
          images: {
            poster: content.image_variants_for("poster"),
            backdrop: content.image_variants_for("backdrop"),
            logo: content.image_variants_for("logo")
          }
        }
      end
      CinelarTV.cache.write("top_10_content_#{country_code}", serialized)
      Rails.logger.info("Top 10 content for country #{country_code} saved on Redis, #{serialized.size} contents.")
    end
  end
end
