# frozen_string_literal: true

module Admin
  class IconPickerController < BaseController
    skip_before_action :verify_authenticity_token

    def search
      icons = SvgSprite.icon_picker_search(params[:filter])
      render json: icons
    end
  end
end
