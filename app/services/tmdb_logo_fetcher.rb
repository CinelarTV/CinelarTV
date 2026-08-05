# frozen_string_literal: true

require "open-uri"

class TmdbLogoFetcher
  TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/original"

  def initialize(content)
    @content = content
  end

  def call
    return if @content.tmdb_id.blank?
    return if SiteSetting.tmdb_api_key.blank?

    logo_path = fetch_logo_path
    return unless logo_path

    temp_file = download_logo(logo_path)
    return unless temp_file

    ImageProcessingJob.perform_async("Content", @content.id, "logo", temp_file)
  end

  private

  def fetch_logo_path
    api_key = SiteSetting.tmdb_api_key.strip
    language = SiteSetting.default_locale
    endpoint = tmdb_images_endpoint

    url = "#{endpoint}?api_key=#{api_key}&include_image_language=#{language},en,null"
    response = HTTParty.get(url)
    data = response.parsed_response

    logos = data["logos"] || []
    return if logos.empty?

    preferred = logos.find { |l| l["iso_639_1"] == language.to_s.split("-").first } ||
                logos.find { |l| l["iso_639_1"] == "en" } ||
                logos.first

    preferred&.dig("file_path")
  end

  def tmdb_images_endpoint
    if @content.content_type == "MOVIE"
      "https://api.themoviedb.org/3/movie/#{@content.tmdb_id}/images"
    else
      "https://api.themoviedb.org/3/tv/#{@content.tmdb_id}/images"
    end
  end

  def download_logo(file_path)
    url = "#{TMDB_IMAGE_BASE}#{file_path}"
    temp_dir = Rails.root.join("tmp", "uploads")
    FileUtils.mkdir_p(temp_dir)

    ext = File.extname(file_path).delete(".")
    ext = "png" if ext.blank?

    temp_file = File.join(temp_dir, "#{SecureRandom.uuid}_logo.#{ext}")
    URI.open(url) do |downloaded_file|
      File.binwrite(temp_file, downloaded_file.read)
    end

    temp_file
  rescue StandardError => e
    Rails.logger.warn("TmdbLogoFetcher: failed to download logo for content #{@content.id}: #{e.message}")
    nil
  end
end
