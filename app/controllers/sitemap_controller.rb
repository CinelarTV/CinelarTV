# frozen_string_literal: true

class SitemapController < ApplicationController
  def index
    base_scope = Content.available.where.not(title: [nil, ""])
    @contents = base_scope.includes(seasons: :episodes).order(updated_at: :desc)

    canonical_base = SiteSetting.base_url.presence || request.base_url
    episode_scope = Episode.joins(season: :content).merge(base_scope)

    content_count = base_scope.count
    episode_count = episode_scope.count
    latest_content_at = base_scope.maximum(:updated_at)
    latest_episode_at = episode_scope.maximum(:updated_at)
    latest_update_at = [latest_content_at, latest_episode_at].compact.max || Time.current
    revision = latest_update_at.to_i

    sitemap_cache_key = [
      "sitemap",
      canonical_base,
      content_count,
      episode_count,
      revision
    ].join(":")

    # 404 if sitemap is disabled
    Rails.logger.info "Sitemap enabled: #{SiteSetting.enable_sitemap}"
    if SiteSetting.enable_sitemap
      expires_in 30.minutes, public: true

      xml = Rails.cache.fetch(sitemap_cache_key, expires_in: 30.minutes) do
        render_to_string(template: "sitemap/index", formats: [:xml], layout: false)
      end

      render xml: xml
    else
      # Render application/index.html.erb (Format: HTML)
      render "application/index", status: :not_found, formats: :html
    end
  end
end
