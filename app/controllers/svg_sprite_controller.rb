# frozen_string_literal: true

class SvgSpriteController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    return head :not_found unless SiteSetting.experimental_icon_engine

    bundle = SvgSprite.cached_bundle
    etag = %("#{SvgSprite.version}")

    if request.headers["If-None-Match"] == etag
      head :not_modified
      return
    end

    response.headers["Content-Type"] = "image/svg+xml"
    response.headers["Cache-Control"] = "public, max-age=0"
    response.headers["ETag"] = etag
    render plain: bundle
  end
end
