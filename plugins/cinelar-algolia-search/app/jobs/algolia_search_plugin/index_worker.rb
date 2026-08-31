# frozen_string_literal: true

module AlgoliaSearchPlugin
  class IndexWorker
    include Sidekiq::Job
    sidekiq_options queue: :algolia_indexing, retry: 3

    def perform(model_name, record_id, remove = false)
      model = model_name.constantize
      index_name = "#{SiteSetting.cinelar_algolia_index_prefix}#{model.model_name.plural}_#{Rails.env}"

      ensure_configured!
      client = ::AlgoliaSearch.client

      if remove
        client.delete_objects(index_name, [record_id.to_s])
      else
        record = model.find_by(id: record_id)
        return unless record
        client.add_object(index_name, record.as_json.merge("objectID" => record.id.to_s))
      end
    rescue => e
      Rails.logger.error("[Algolia] IndexWorker failed for #{model_name}##{record_id}: #{e.message}")
      raise
    end

    private

    def ensure_configured!
      return if @configured

      app_id = SiteSetting.cinelar_algolia_app_id
      api_key = SiteSetting.cinelar_algolia_admin_api_key

      if app_id.present? && api_key.present?
        ::AlgoliaSearch.configuration = {
          application_id: app_id,
          api_key: api_key
        }
        ::AlgoliaSearch.send(:setup_client)
      end

      @configured = true
    end
  end
end
