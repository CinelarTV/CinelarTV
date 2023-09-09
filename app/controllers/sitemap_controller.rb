# frozen_string_literal: true

class SitemapController < ApplicationController
  def index
    @contents = Content.all
    # 404 if sitemap is disabled
    Rails.logger.info "Sitemap enabled: #{SiteSetting.enable_sitemap}"
    if !SiteSetting.enable_sitemap
      render status: :not_found
    else
      respond_to do |format|
        format.xml
      end
    end
  end
end
