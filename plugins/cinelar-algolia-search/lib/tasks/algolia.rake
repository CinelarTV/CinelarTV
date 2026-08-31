# frozen_string_literal: true

namespace :algolia do
  task :setup_algolia_models => :environment do
    require "algoliasearch-rails"
    require_relative "../../app/models/algolia_searchable"
    [Content, Person, Category].each do |klass|
      klass.include AlgoliaSearchPlugin::AlgoliaSearchable unless klass.include?(AlgoliaSearchPlugin::AlgoliaSearchable)
    end
  end

  desc "Reindex all Algolia models"
  task reindex_all: :setup_algolia_models do
    puts "Reindexing Content..."
    Content.reindex
    puts "Reindexing Person..."
    Person.reindex
    puts "Reindexing Category..."
    Category.reindex
    puts "Done."
  end

  desc "Reindex a specific model (e.g. rake algolia:reindex[Content])"
  task :reindex, [:model_name] => :setup_algolia_models do |_t, args|
    model = args[:model_name].constantize
    puts "Reindexing #{model.name}..."
    model.reindex
    puts "Done."
  end

  desc "Clear all Algolia indices"
  task clear_all: :setup_algolia_models do
    client = ::AlgoliaSearch.client
    prefix = SiteSetting.cinelar_algolia_index_prefix
    %w[contents people categories].each do |name|
      index_name = "#{prefix}#{name}_#{Rails.env}"
      puts "Clearing #{index_name}..."
      client.clear_index(index_name)
    end
    puts "Done."
  end
end
