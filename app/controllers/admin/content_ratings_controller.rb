# frozen_string_literal: true

module Admin
  class ContentRatingsController < Admin::BaseController
    def index
      ratings = ContentRating.active.ordered
      locale = I18n.locale

      render json: {
        data: ratings.map { |r| r.as_json_with_locale(locale: locale) }
      }
    end
  end
end
