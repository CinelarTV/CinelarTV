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
    scope = if @term.present?
              Content.where("search_data @@ plainto_tsquery('simple', :term)", term: @term)
            else
              Content.where.not(search_data: nil)
            end

    scope = scope.where(content_type: @filters[:content_type]) if @filters[:content_type]
    scope = scope.where(year: @filters[:year]) if @filters[:year]
    if @filters.key?(:premium)
      scope = scope.where(premium: @filters[:premium])
    end
    if @filters[:category]
      scope = scope.joins(:categories).where(
        "unaccent(lower(categories.name)) LIKE unaccent(?)",
        "%#{@filters[:category].downcase}%"
      )
    end

    scope = scope.where(available: true)

    if @term.present?
      scope = scope.order(Arel.sql(<<~SQL.squish))
        ts_rank_cd(search_data, plainto_tsquery('simple', #{ActiveRecord::Base.connection.quote(@term)})) DESC
      SQL
    else
      scope = scope.order(created_at: :desc)
    end

    scope.includes(:image_variants, :categories).limit(@per_page).offset((@page - 1) * @per_page)
  end

  def search_people
    return Person.none if @term.blank?

    Person.where("unaccent(lower(name)) LIKE unaccent(?)", "%#{@term}%")
          .limit(5)
  end

  def search_categories
    return Category.none if @term.blank?

    Category.where("unaccent(lower(name)) LIKE unaccent(?)", "%#{@term}%")
            .limit(5)
  end

  def empty_result
    { contents: [], people: [], categories: [], meta: @meta }
  end
end
