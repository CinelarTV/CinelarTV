# frozen_string_literal: true

class SitemapController < ApplicationController
  def index
    @contents = Content.all
    # 404 if sitemap is disabled
    Rails.logger.info "Sitemap enabled: #{SiteSetting.enable_sitemap}"
    if SiteSetting.enable_sitemap
      # rubocop:disable Style/SymbolProc
      respond_to do |format|
        format.xml
      end
    else
      # Render application/index.html.erb (Format: HTML)
      render "application/index", status: :not_found, formats: :html
    end
  end
end
