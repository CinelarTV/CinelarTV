# frozen_string_literal: true

# name: cinelar-algolia-search
# version: 1.0.0
# authors: CinelarTV
# url: https://github.com/cinelartv/cinelar-algolia-search
# required_version: 0.0.1

gem "algoliasearch-rails", "3.0.2"
gem "algolia", "3.5.2"
gem "faraday", "2.14.3"
gem "faraday-net_http", "3.4.4", require_name: "faraday/net_http"
gem "faraday-net_http_persistent", "2.3.1", require_name: "faraday/net_http_persistent"
gem "net-http-persistent", "4.0.8", require_name: "net/http/persistent"
gem "base64", "0.3.0"

after_initialize do
  require "algoliasearch-rails"

  register_js("app/assets/javascripts/index.ts")
  register_css("app/assets/styles/algolia-search.css")

  require_relative "app/models/concerns/algolia_searchable"
  require_relative "app/services/algolia_search/search_service"
  require_relative "app/jobs/algolia/index_worker"

  reloadable_patch do
    [Content, Person, Category].each do |klass|
      klass.include AlgoliaSearchPlugin::AlgoliaSearchable unless klass.include?(AlgoliaSearchPlugin::AlgoliaSearchable)
    end
  end

  add_to_class(:contents_controller, :search) do
    query = (params[:q] || params[:query]).to_s.strip

    if query.blank? || query.length < 2
      respond_to do |format|
        format.html
        format.json do
          render json: {
            errors: [I18n.t("contents.search.query_required")],
            error_type: "query_required",
          }, status: :unprocessable_entity
        end
      end
      return
    end

    if SiteSetting.cinelar_algolia_enabled == true
      results = AlgoliaSearchPlugin::SearchService.new.search(query: query, hitsPerPage: 30)
      respond_to do |format|
        format.html
        format.json { render json: { data: results } }
      end
    else
      result = ContentSearchService.new(
        term: query,
        profile: current_profile,
        page: params[:page],
        per_page: params[:per_page]
      ).execute

      respond_to do |format|
        format.html
        format.json {
          render json: {
            data: result[:contents].as_json(only: %i[id title description banner content_type year], methods: [:available]),
            people: result[:people].as_json(only: %i[id name profile_path]),
            categories: result[:categories].as_json(only: %i[id name]),
            meta: result[:meta]
          }
        }
      end
    end
  end
end

require_relative "lib/algolia_search/engine"
