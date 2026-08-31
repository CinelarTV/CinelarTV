# frozen_string_literal: true

module AlgoliaSearchPlugin
  class IndexWorker
    include Sidekiq::Job
    sidekiq_options queue: :algolia_indexing, retry: 3

    def perform(model_name, record_id, remove = false)
      model = model_name.constantize
      index_name = "#{SiteSetting.cinelar_algolia_index_prefix}#{model.model_name.plural}_#{Rails.env}"

      client = AlgoliaSearchPlugin.build_client

      if remove
        client.delete_objects(index_name, [record_id.to_s])
      else
        record = model.find_by(id: record_id)
        return unless record
        client.add_or_update_object(index_name, record.id.to_s, record.as_json)
      end
    rescue => e
      Rails.logger.error("[Algolia] IndexWorker failed for #{model_name}##{record_id}: #{e.message}")
      raise
    end
  end
end
