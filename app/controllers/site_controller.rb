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

  def settings
    render json:  SiteSetting.exposed_settings
    
  end

  private

  def device
    agent = request.user_agent
    return "tablet" if agent =~ /(tablet|ipad)|(android(?!.*mobile))/i
    return "mobile" if agent =~ /Mobile/

    "desktop"
  end

  def build_user_data
    return nil unless current_user

    CurrentUserSerializer.new(current_user, {
      include_profiles: true,
      current_profile_id: session[:current_profile_id]
    }).serializable_hash
  end
end
