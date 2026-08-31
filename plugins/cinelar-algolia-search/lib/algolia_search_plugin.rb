# frozen_string_literal: true

module AlgoliaSearchPlugin
  def self.build_client
    app_id = SiteSetting.cinelar_algolia_app_id
    api_key = SiteSetting.cinelar_algolia_admin_api_key

    raise "Algolia not configured: missing app_id or api_key" if app_id.blank? || api_key.blank?

    ::Algolia::SearchClient.create(app_id, api_key)
  end
end
