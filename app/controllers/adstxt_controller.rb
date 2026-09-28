# frozen_string_literal: true

class AdstxtController < ApplicationController
  skip_before_action :require_finish_installation?
  skip_before_action :check_maintenance_mode
  skip_before_action :check_profile_if_signed_in
  skip_before_action :ensure_account_active

  layout false

  def index
    raise CinelarTV::NotFound if SiteSetting.ads_txt.blank?

    render plain: SiteSetting.ads_txt, content_type: "text/plain"
  end
end
