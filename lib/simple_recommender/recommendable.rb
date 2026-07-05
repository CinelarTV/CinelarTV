# frozen_string_literal: true

# Modified version of https://github.com/geoffreylitt/simple_recommender
# CinelarTV uses UUIDs for primary keys, so we need to modify the gem

module SimpleRecommender
  module Recommendable
    extend ActiveSupport::Concern
    DEFAULT_N_RESULTS = 10
    AssociationMetadata = Struct.new(:join_table, :foreign_key, :association_foreign_key)

    module ClassMethods
      def similar_by(association_name)
        define_method :similar_items do |n_results: DEFAULT_N_RESULTS|
          self.class.find_by_sql(
            similar_query(association_name:, n_results:)
          )
        end
      end
    end

    included do
      private

      def association_metadata(reflection)
        case reflection
        when ActiveRecord::Reflection::HasAndBelongsToManyReflection
          AssociationMetadata.new(
            reflection.join_table,
            reflection.foreign_key,
            reflection.association_foreign_key
          )
        when ActiveRecord::Reflection::ThroughReflection
          AssociationMetadata.new(
            reflection.through_reflection.table_name,
            reflection.through_reflection.foreign_key,
            reflection.association_foreign_key
          )
        else
          raise ArgumentError, "Association '#{reflection.name}' is not a supported type"
        end
      end

      def similar_query(association_name:, n_results:)
        reflection = self.class.reflect_on_association(association_name)
        raise ArgumentError, "Could not find association #{association_name}" if reflection.nil?

        metadata   = association_metadata(reflection)
        join_table = metadata[:join_table]
        fkey       = metadata[:foreign_key]
        assoc_fkey = metadata[:association_foreign_key]
        this_table = self.class.table_name

        [join_table, fkey, assoc_fkey, this_table].each do |name|
          raise ArgumentError, "Invalid identifier: #{name}" unless name.match?(/\A[a-zA-Z_][a-zA-Z0-9_.]*\z/)
        end

        [<<-SQL, id, id, n_results]
          WITH
            self_tags AS (
              SELECT
                array_agg(DISTINCT #{assoc_fkey}) AS tags,
                COUNT(DISTINCT #{assoc_fkey})     AS cnt
              FROM #{join_table}
              WHERE #{fkey} = ?
            ),
            candidate_tags AS (
              SELECT
                #{fkey},
                array_agg(DISTINCT #{assoc_fkey}) AS tags,
                COUNT(DISTINCT #{assoc_fkey})     AS cnt
              FROM #{join_table}
              WHERE #{fkey} != ?
              GROUP BY #{fkey}
            ),
            similarities AS (
              SELECT
                c.#{fkey},
                (
                  SELECT COUNT(*)
                  FROM (
                    SELECT unnest(s.tags)
                    INTERSECT
                    SELECT unnest(c.tags)
                  ) AS intersection
                )::float / NULLIF(
                  s.cnt + c.cnt - (
                    SELECT COUNT(*)
                    FROM (
                      SELECT unnest(s.tags)
                      INTERSECT
                      SELECT unnest(c.tags)
                    ) AS intersection
                  ), 0
                ) AS similarity
              FROM candidate_tags c, self_tags s
              ORDER BY similarity DESC
              LIMIT ?
            )
          SELECT #{this_table}.*, similarity
          FROM similarities
          JOIN #{this_table} ON #{this_table}.id = similarities.#{fkey}
          WHERE #{this_table}.available = TRUE
          ORDER BY similarity DESC
        SQL
      end

      # Combine results from multiple similarity sources with weights.
      # sources: [{ assoc: :liking_profiles, weight: 0.7 }, { assoc: :people, weight: 0.3 }]
      def combined_similar_items(sources, n_results: DEFAULT_N_RESULTS)
        # Collect results from each source
        source_results = sources.map do |source|
          results = self.class.find_by_sql(
            similar_query(association_name: source[:assoc], n_results: n_results * 2)
          )
          [source[:weight], results]
        end

        # Merge by content id, computing weighted scores
        scores = Hash.new { |h, k| h[k] = 0.0 }
        records = {}

        source_results.each do |weight, results|
          results.each do |record|
            sim = record.respond_to?(:similarity) ? (record.similarity || 0).to_f : 0.0
            scores[record.id] += sim * weight
            records[record.id] = record
          end
        end

        # Sort by combined score, take top N
        top_ids = scores.sort_by { |_, score| -score }.first(n_results).map(&:first)
        return [] if top_ids.empty?

        # Re-fetch full records (with associations) in correct order
        record_map = self.class.where(id: top_ids).index_by(&:id)
        top_ids.filter_map { |id| record_map[id] }
      end
    end
  end
end
