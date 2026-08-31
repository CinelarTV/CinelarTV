# frozen_string_literal: true

namespace :algolia do
  task setup_algolia_models: :environment do
    require_relative "../../lib/algolia_search_plugin"
    require_relative "../../app/models/algolia_search_plugin"
    require_relative "../../app/models/algolia_search_plugin/algolia_searchable"
    [Content, Person, Category].each do |klass|
      klass.include AlgoliaSearchPlugin::AlgoliaSearchable unless klass.include?(AlgoliaSearchPlugin::AlgoliaSearchable)
    end
  end

  desc "Reindex all Algolia models"
  task reindex_all: :setup_algolia_models do
    client = AlgoliaSearchPlugin.build_client
    prefix = SiteSetting.cinelar_algolia_index_prefix
    env = Rails.env

    %w[contents people categories].each do |name|
      index_name = "#{prefix}#{name}_#{env}"
      puts "Reindexing #{index_name}..."
      model = name.classify.constantize
      model.find_each do |record|
        client.add_or_update_object(index_name, record.id.to_s, record.as_json)
      end
    end
    puts "Done."
  end

  desc "Reindex a specific model (e.g. rake algolia:reindex[Content])"
  task :reindex, [:model_name] => :setup_algolia_models do |_t, args|
    model = args[:model_name].constantize
    client = AlgoliaSearchPlugin.build_client
    index_name = "#{SiteSetting.cinelar_algolia_index_prefix}#{model.model_name.plural}_#{Rails.env}"
    puts "Reindexing #{model.name} into #{index_name}..."
    model.find_each do |record|
      client.add_or_update_object(index_name, record.id.to_s, record.as_json)
    end
    puts "Done."
  end

  desc "Clear all Algolia indices"
  task clear_all: :setup_algolia_models do
    client = AlgoliaSearchPlugin.build_client
    prefix = SiteSetting.cinelar_algolia_index_prefix
    %w[contents people categories].each do |name|
      index_name = "#{prefix}#{name}_#{Rails.env}"
      puts "Clearing #{index_name}..."
      client.clear_objects(index_name)
    end
    puts "Done."
  end
end
