# frozen_string_literal: true

class SitemapController < ApplicationController
  def index
    @contents = Content.all
    # 404 if sitemap is disabled
    Rails.logger.info "Sitemap enabled: #{SiteSetting.enable_sitemap}"
    if SiteSetting.enable_sitemap
      respond_to(&:xml)
    else
      render status: :not_found
    end
  end
end
