# frozen_string_literal: true

module Admin
  class ContentDescriptorsController < Admin::BaseController
    def index
      descriptors = ContentDescriptor.active.ordered
      locale = I18n.locale

      render json: {
        data: descriptors.map { |d| d.as_json_with_locale(locale: locale) }
      }
    end
  end
end
