# frozen_string_literal: true

module AlgoliaSearchPlugin
  class ConfigController < ApplicationController
    def show
      render json: {
        app_id: SiteSetting.cinelar_algolia_app_id,
        search_api_key: SiteSetting.cinelar_algolia_search_api_key,
        index_prefix: SiteSetting.cinelar_algolia_index_prefix,
        environment: Rails.env
      }
    end
  end
end
