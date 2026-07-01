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
    head :not_found unless SiteSetting.enable_sitemap
  end

  def canonical_base
    @canonical_base ||= (SiteSetting.base_url.presence || (request.protocol + request.host_with_port)).sub(%r{/\z}, "")
  end

  helper_method :canonical_base

  def sitemap_index_cache_key
    content_count = Content.available.count
    episode_count = Episode.joins(season: :content).where(contents: { available: true }).count
    latest_content_at = Content.available.maximum(:updated_at)
    latest_episode_at = Episode.joins(season: :content).where(contents: { available: true }).maximum(:updated_at)
    latest_update_at = [latest_content_at, latest_episode_at].compact.max || Time.current

    [
      "sitemap:index",
      canonical_base,
      content_count,
      episode_count,
      latest_update_at.to_i
    ].join(":")
  end

  def sitemap_contents_cache_key(contents)
    latest_updated = contents.maximum(:updated_at) || Time.current
    ["sitemap:contents", canonical_base, contents.count, latest_updated.to_i].join(":")
  end

  def sitemap_episodes_cache_key(episodes)
    latest_updated = episodes.maximum(:updated_at) || Time.current
    ["sitemap:episodes", canonical_base, episodes.count, latest_updated.to_i].join(":")
  end
end
