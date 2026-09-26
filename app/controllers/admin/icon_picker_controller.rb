# frozen_string_literal: true

module Admin
  class IconPickerController < BaseController
    skip_before_action :verify_authenticity_token
    wrap_parameters false

    def search
      icons = SvgSprite.icon_picker_search(params[:filter])
      render json: icons
    end
  end
end
