class SiteController < ApplicationController
  def info
    render json: {
      site_name: SiteSetting.site_name || "CinelarTV",
      logo_url: SiteSetting.site_logo || view_context.asset_url("logo.png"),
      description: "La mejor plataforma de streaming independiente",
      contact_email: "info@cinelartv.com",
      version: (defined?(CinelarTv::VERSION) ? CinelarTv::VERSION : nil)
    }
  end
end
