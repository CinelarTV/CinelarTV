# frozen_string_literal: true

class SitemapController < ApplicationController
  layout false

  skip_before_action :check_profile_if_signed_in
  before_action :ensure_sitemap_enabled

  def index
    expires_in 30.minutes, public: true

    xml = Rails.cache.fetch(sitemap_index_cache_key, expires_in: 30.minutes) do
      render_to_string(template: "sitemap/index", formats: [:xml])
    end

    render xml: xml
  end

  def contents
    @contents = Content.available
                       .where.not(title: [nil, ""])
                       .includes(seasons: :episodes)
                       .order(updated_at: :desc)

    expires_in 30.minutes, public: true

    xml = Rails.cache.fetch(sitemap_contents_cache_key(@contents), expires_in: 30.minutes) do
      render_to_string(template: "sitemap/contents", formats: [:xml])
    end

    render xml: xml
  end

  def episodes
    @episodes = Episode.joins(season: :content)
                       .where(contents: { available: true })
                       .where.not(episodes: { title: [nil, ""] })
                       .includes(season: :content)
                       .order("episodes.updated_at DESC")

    expires_in 30.minutes, public: true

    xml = Rails.cache.fetch(sitemap_episodes_cache_key(@episodes), expires_in: 30.minutes) do
      render_to_string(template: "sitemap/episodes", formats: [:xml])
    end

    render xml: xml
  end

  private

  def ensure_sitemap_enabled
   raise CinelarTV::NotFound unless SiteSetting.sitemap_enabled
  end

  def canonical_base
    @canonical_base ||= (SiteSetting.base_url.presence || (request.protocol + request.host_with_port)).sub(%r{/\z}, "")
  end

  helper_method :canonical_base

  # Claves basadas en tiempo (bucket de 30 min) — elimina COUNT/MAX queries por request.
  # El sitemap se regenera cada 30 min automáticamente.
  def sitemap_index_cache_key
    "sitemap:index:#{canonical_base}:#{Time.current.to_i / 30.minutes.to_i}"
  end

  def sitemap_contents_cache_key(_contents)
    "sitemap:contents:#{canonical_base}:#{Time.current.to_i / 30.minutes.to_i}"
  end

  def sitemap_episodes_cache_key(_episodes)
    "sitemap:episodes:#{canonical_base}:#{Time.current.to_i / 30.minutes.to_i}"
  end
end
