# frozen_string_literal: true

module AlgoliaSearchPlugin
  class SearchService
    INDICES = %w[contents people categories].freeze

    def initialize
      @client = AlgoliaSearchPlugin.build_client
    end

    def search(query:, hitsPerPage: 30, page: 0)
      results = []

      INDICES.each do |index_name|
        index_results = @client.search_single_index(
          prefixed_index(index_name),
          { query: query, hitsPerPage: hitsPerPage, page: page }
        )
        next unless index_results&.hits

        index_results.hits.each do |hit|
          data = hit.to_hash.stringify_keys
          results << format_hit(data, index_name)
        end
      end

      results
    rescue ::Algolia::AlgoliaHttpError => e
      Rails.logger.error("[Algolia] Search failed: #{e.message}")
      []
    end

    private

    def format_hit(hit, index_name)
      case index_name
      when "contents"
        {
          id: hit["objectID"],
          title: hit["title"],
          description: hit["description"],
          banner: hit["banner"],
          content_type: hit["content_type"],
          available: true,
          result_type: "content"
        }
      when "people"
        {
          id: hit["objectID"],
          name: hit["name"],
          profile_path: hit["profile_path"],
          known_for_department: hit["known_for_department"],
          result_type: "person"
        }
      when "categories"
        {
          id: hit["objectID"],
          name: hit["name"],
          description: hit["description"],
          result_type: "category"
        }
      end
    end

    def prefixed_index(name)
      "#{SiteSetting.cinelar_algolia_index_prefix}#{name}_#{Rails.env}"
    end
  end
end
