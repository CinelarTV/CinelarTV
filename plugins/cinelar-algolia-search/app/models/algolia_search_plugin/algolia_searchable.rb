# frozen_string_literal: true

module AlgoliaSearchPlugin
  module AlgoliaSearchable
    extend ActiveSupport::Concern

    included do
      after_commit :algolia_enqueue_sync, if: :algolia_searchable?
    end

    class_methods do
      def algolia_enqueue_job(record, remove)
        return unless SiteSetting.cinelar_algolia_enabled == true
        AlgoliaSearchPlugin::IndexWorker.perform_async(record.class.name, record.id, remove)
      end

      def algolia_index_name
        "#{SiteSetting.cinelar_algolia_index_prefix}#{model_name.plural}_#{Rails.env}"
      end
    end

    private

    def algolia_searchable?
      SiteSetting.cinelar_algolia_enabled == true
    end

    def algolia_enqueue_sync
      return unless algolia_searchable?
      self.class.algolia_enqueue_job(self, false)
    end
  end
end
