# frozen_string_literal: true

class ContentSearchService
  attr_reader :meta

  def initialize(term:, profile: nil, page: 1, per_page: 30)
    @term = term.to_s.strip
    @original_term = @term.dup
    @profile = profile
    @page = [page.to_i, 1].max
    @per_page = [[per_page.to_i, 1].max, 50].min
    @per_page = 30 if per_page.to_i <= 0
    @filters = {}
    @meta = { query: @original_term, filters: {}, page: @page, per_page: @per_page }
  end

  def execute
    return empty_result if @term.length < 2

    clean_term!
    parse_advanced_filters!

    results = {
      contents: search_contents,
      people: search_people,
      categories: search_categories
    }

    @meta[:total_contents] = results[:contents].size
    results[:meta] = @meta
    results
  end

  private

  def clean_term!
    @term = @term.downcase
    @term = @term.gsub(/[\u200B-\u200D\uFEFF]/, "")
    @term = @term.gsub(/[\u201c\u201d]/, '"')
    @term = @term.gsub(/[\u02b9\u02bb\u02bc\u02bd\u02c8\u2018\u2019\u201b\u2032\uff07]/, "'")
    @term = @term.strip
  end

  def parse_advanced_filters!
    patterns = {
      /\Atype:(movie|series|tvshow)\z/i => ->(m) { @filters[:content_type] = m[1].downcase.in?(%w[series tvshow]) ? "TVSHOW" : "MOVIE" },
      /\Acategory:(.+)\z/i => ->(m) { @filters[:category] = m[1].strip },
      /\Ayear:(\d{4})\z/i => ->(m) { @filters[:year] = m[1].to_i },
      /\Ais:(premium|free)\z/i => ->(m) { @filters[:premium] = m[1] == "premium" }
    }

    remaining = @term.split(/\s+/).filter_map do |word|
      matched = patterns.find { |regex, _| word.match?(regex) }
      if matched
        matched[1].call(word.match(matched[0]))
        nil
      else
        word
      end
    end

    @term = remaining.join(" ").strip
    @meta[:filters] = @filters
  end

  def search_contents
    scope = Content.where(available: true)

    if @term.present?
      clean_search_term = @term.gsub(/["']/, "").strip
      tsq = tsquery_term(clean_search_term)
      like_term = "%#{clean_search_term}%"
      starts_with_term = "#{clean_search_term}%"

      if tsq.present?
        scope = scope.where(
          "search_data @@ to_tsquery('simple', immutable_unaccent(:tsq)) OR lower(immutable_unaccent(title)) LIKE immutable_unaccent(:like)",
          tsq: tsq,
          like: like_term
        )

        scope = scope.order(Arel.sql(ActiveRecord::Base.sanitize_sql_array([
          <<~SQL.squish,
            CASE
              WHEN lower(immutable_unaccent(title)) = immutable_unaccent(?) THEN 1
              WHEN lower(immutable_unaccent(title)) LIKE immutable_unaccent(?) THEN 2
              WHEN lower(immutable_unaccent(title)) LIKE immutable_unaccent(?) THEN 3
              ELSE 4
            END ASC,
            ts_rank_cd(search_data, to_tsquery('simple', immutable_unaccent(?))) DESC,
            created_at DESC
          SQL
          clean_search_term,
          starts_with_term,
          like_term,
          tsq
        ])))
      else
        scope = scope.where("lower(immutable_unaccent(title)) LIKE immutable_unaccent(?)", like_term)
        scope = scope.order(created_at: :desc)
      end
    else
      scope = scope.where.not(search_data: nil).order(created_at: :desc)
    end

    scope = scope.where(content_type: @filters[:content_type]) if @filters[:content_type]
    scope = scope.where(year: @filters[:year]) if @filters[:year]
    scope = scope.where(premium: @filters[:premium]) if @filters.key?(:premium)

    if @filters[:category]
      scope = scope.joins(:categories).where(
        "unaccent(lower(categories.name)) LIKE unaccent(?)",
        "%#{@filters[:category].downcase}%"
      )
    end

    scope.includes(:image_variants, :categories).limit(@per_page).offset((@page - 1) * @per_page)
  end

  def tsquery_term(term)
    tokens = term.to_s.scan(/[\p{L}\p{N}]+/)
    return nil if tokens.empty?

    tokens.map { |t| "#{t}:*" }.join(" & ")
  end

  def search_people
    return Person.none if @term.blank?

    search_term = @term.gsub(/["']/, "").strip
    return Person.none if search_term.blank?

    Person.where("unaccent(lower(name)) LIKE unaccent(?)", "%#{search_term}%")
          .order(Arel.sql(ActiveRecord::Base.sanitize_sql_array([
            "CASE WHEN unaccent(lower(name)) LIKE unaccent(?) THEN 1 ELSE 2 END ASC, name ASC",
            "#{search_term}%"
          ])))
          .limit(5)
  end

  def search_categories
    return Category.none if @term.blank?

    search_term = @term.gsub(/["']/, "").strip
    return Category.none if search_term.blank?

    Category.where("unaccent(lower(name)) LIKE unaccent(?)", "%#{search_term}%")
          .order(Arel.sql(ActiveRecord::Base.sanitize_sql_array([
            "CASE WHEN unaccent(lower(name)) LIKE unaccent(?) THEN 1 ELSE 2 END ASC, name ASC",
            "#{search_term}%"
          ])))
          .limit(5)
  end

  def empty_result
    { contents: [], people: [], categories: [], meta: @meta }
  end
end
