# frozen_string_literal: true

module HomeHelper
  def homepage_data
    @homepage_data ||= begin
      ids_set = liked_content_ids
      include_trailers = params[:include_trailers] == "true"

      banner = load_banner_content(ids_set)
      sections = build_content_sections(ids_set)

      if include_trailers
        inject_trailers_into_content(banner)
        inject_trailers_into_sections(sections)
      end

      {
        banner_content: banner,
        content: sections
      }
    end
  end

  def load_shuffle_recommendations
    liked_ids = liked_content_ids

    contents = Content.where(available: true)
                      .where.not(trailer_url: nil)
                      .order("RANDOM()")
                      .limit(10)
                      .pluck(:id, :title, :description, :banner, :trailer_url, :content_type, :year)

    content_ids = contents.map(&:first)

    trailer_sources = VideoSource.where(trailer: true, videoable_id: content_ids, videoable_type: "Content")
                                 .pluck(:videoable_id, :url, :format, :quality)
                                 .group_by(&:first)

    contents.map do |id, title, desc, banner, trailer_url, content_type, year|
      sources = (trailer_sources[id] || []).map do |_, url, fmt, qlt|
        { url: url, format: fmt, quality: qlt }
      end

      {
        id: id,
        title: title,
        description: desc,
        banner: banner,
        trailer_url: trailer_url,
        trailer_sources: sources,
        trailer_mime_type: infer_trailer_mime_type(trailer_url, sources),
        content_type: content_type,
        year: year,
        liked: liked_ids.include?(id)
      }
    end
  end

  private

  def liked_content_ids
    @liked_content_ids ||= Set.new(current_profile&.liked_contents&.pluck(:id) || [])
  end

  def infer_trailer_mime_type(url, sources)
    if sources.any? { |s| s[:format] == "m3u8" }
      return "application/x-mpegurl"
    end

    case url.to_s
    when /\.m3u8/i then "application/x-mpegurl"
    when /\.webm/i then "video/webm"
    else "video/mp4"
    end
  end

  def load_banner_content(liked_ids)
    if (profile = current_profile)
      personalized_banner_content(liked_ids, profile)
    else
      random_banner_content(liked_ids)
    end
  end

  def personalized_banner_content(liked_ids, profile)
    liked_category_ids = liked_category_ids_for(profile)

    Content.where(available: true)
           .where.not(banner: nil)
           .left_joins(:content_analytic)
           .order(Arel.sql(banner_score_sql(liked_category_ids, profile.id)))
           .limit(10)
           .pluck(:id, :title, :description, :banner, :banner_resized, :cover_resized)
           .map do |id, title, desc, banner, banner_resized, cover_resized|
             build_content_hash(id, title, desc, banner, liked_ids, banner_resized: banner_resized,
                                                                    cover_resized: cover_resized)
           end
  end

  def random_banner_content(liked_ids)
    Content.where(available: true)
           .where.not(banner: nil)
           .order("RANDOM()")
           .limit(10)
           .pluck(:id, :title, :description, :banner, :banner_resized, :cover_resized)
           .map do |id, title, desc, banner, banner_resized, cover_resized|
             build_content_hash(id, title, desc, banner, liked_ids, banner_resized: banner_resized,
                                                                    cover_resized: cover_resized)
           end
  end

  def liked_category_ids_for(profile)
    liked_ids = profile.liked_contents.pluck(:id)
    return [] if liked_ids.empty?

    ContentCategory.where(content_id: liked_ids)
                   .distinct
                   .pluck(:category_id)
  end

  def banner_score_sql(liked_category_ids, profile_id)
    connection = ActiveRecord::Base.connection
    quoted_pid = connection.quote(profile_id)

    scores = []

    #
    # 1. Continue Watching
    # La señal más fuerte del banner.
    #
    scores << <<~SQL.squish
      CASE
        WHEN EXISTS (
          SELECT 1
          FROM continue_watchings cw
          WHERE cw.content_id = contents.id
            AND cw.profile_id = #{quoted_pid}
            AND cw.finished = FALSE
            AND cw.progress > 0
        )
        THEN 100
        ELSE 0
      END
    SQL

    #
    # 2. Afinidad con categorías favoritas
    # Suma 15 puntos por cada categoría compartida.
    #
    if liked_category_ids.any?
      ids = liked_category_ids.map { |id| connection.quote(id) }.join(",")

      scores << <<~SQL.squish
        (
          SELECT COUNT(*)
          FROM content_categories cc
          WHERE cc.content_id = contents.id
            AND cc.category_id IN (#{ids})
        ) * 15
      SQL
    end

    #
    # 2b. Afinidad con el elenco (cast)
    # Si el usuario dio like a contenido con ciertos actores,
    # potenciar contenido que comparta esos mismos actores.
    # +10 puntos por actor compartido (máx 50).
    #
    scores << <<~SQL.squish
      LEAST(
        50,
        (
          SELECT COUNT(*)
          FROM cast_members cm
          WHERE cm.content_id = contents.id
            AND cm.person_id IN (
              SELECT DISTINCT cm2.person_id
              FROM likes l
              JOIN cast_members cm2 ON cm2.content_id = l.content_id
              WHERE l.profile_id = #{quoted_pid}
            )
        ) * 10
      )
    SQL

    #
    # 3. Freshness con decaimiento progresivo.
    # Los estrenos reciben un impulso fuerte que desaparece gradualmente.
    #
    scores << <<~SQL.squish
      GREATEST(
        0,
        50 - (
          EXTRACT(EPOCH FROM (NOW() - contents.created_at))
          / 86400.0
        )
      )
    SQL

    #
    # 4. Popularidad usando logaritmo.
    # Evita que los mega hits destruyan el ranking.
    #
    scores << <<~SQL.squish
      LN(GREATEST(COALESCE(content_analytics.total_views, 1), 1)) * 6
    SQL

    #
    # 5. Boost editorial opcional. (Future: Puede ser usado para destacar contenido específico)
    #
    #scores << <<~SQL.squish
    #  CASE
    #    WHEN contents.featured = TRUE
    #    THEN 40
    #    ELSE 0
    #  END
    #SQL

    #
    # 6. Penalizar contenido ya finalizado.
    #
    scores << <<~SQL.squish
      CASE
        WHEN EXISTS (
          SELECT 1
          FROM continue_watchings cw
          WHERE cw.content_id = contents.id
            AND cw.profile_id = #{quoted_pid}
            AND cw.finished = TRUE
        )
        THEN -1000
        ELSE 0
      END
    SQL

    #
    # 7. Exploración controlada.
    #
    scores << "RANDOM() * 2"

    scores.join(" + ")
  end

  def add_added_recently(liked_ids)
    Content.added_recently
           .limit(15)
           .pluck(:id, :title, :description, :banner, :banner_resized, :cover_resized)
           .map do |id, title, desc, banner, banner_resized, cover_resized|
             build_content_hash(id, title, desc, banner, liked_ids, banner_resized: banner_resized,
                                                                    cover_resized: cover_resized)
           end
  end

  def add_recommended_based_on_liked(liked_ids)
    return { title: nil, content: [] } if liked_ids.empty?

    random_liked = Content.find_by(id: liked_ids.to_a.sample)
    return { title: nil, content: [] } unless random_liked

    similar_content = random_liked.similar_items
                                  .reject { |c| c.id == random_liked.id }
                                  .map do |c|
                                    build_content_hash(c.id, c.title, c.description, c.banner, liked_ids,
                                                       banner_resized: c.banner_resized, cover_resized: c.cover_resized)
                                  end

    { title: random_liked.title, content: similar_content }
  end

  def add_most_viewed(liked_ids)
    return [] unless SiteSetting.enable_most_viewed_section

    Content.most_viewed(15)
           .pluck(:id, :title, :description, :banner, :banner_resized, :cover_resized)
           .map do |id, title, desc, banner, banner_resized, cover_resized|
             build_content_hash(id, title, desc, banner, liked_ids, banner_resized: banner_resized,
                                                                    cover_resized: cover_resized)
           end
  end

  def add_most_liked(liked_ids)
    return [] unless SiteSetting.enable_most_liked_section

    Content.most_liked(15)
           .pluck(:id, :title, :description, :banner, :banner_resized, :cover_resized)
           .map do |id, title, desc, banner, banner_resized, cover_resized|
             build_content_hash(id, title, desc, banner, liked_ids, banner_resized: banner_resized,
                                                                    cover_resized: cover_resized)
           end
  end

  def add_by_genre(liked_ids)
    return [] unless SiteSetting.enable_content_by_genre

    shown_ids = Set.new
    per_page = 10

    Category
      .joins(:contents)
      .where(contents: { available: true })
      .group("categories.id")
      .having("COUNT(contents.id) >= 3")
      .order(Arel.sql("COUNT(contents.id) DESC"))
      .limit(6)
      .map do |category|
        content = Content.by_category_id(category.id, per_page * 3)
                         .pluck(:id, :title, :description, :banner, :banner_resized, :cover_resized)
                         .map do |id, title, desc, banner, banner_resized, cover_resized|
                           build_content_hash(id, title, desc, banner, liked_ids, banner_resized: banner_resized,
                                                                                  cover_resized: cover_resized)
                         end
                         .shuffle
                         .reject { |c| shown_ids.include?(c[:id]) }
                         .first(per_page)

        next if content.blank?

        shown_ids.merge(content.map { |c| c[:id] })
        { title: category.name, content: content }
      end
      .compact
  end

  def add_new_this_week(liked_ids)
    Content.new_this_week
           .pluck(:id, :title, :description, :banner, :banner_resized, :cover_resized)
           .map do |id, title, desc, banner, banner_resized, cover_resized|
             build_content_hash(id, title, desc, banner, liked_ids, banner_resized: banner_resized,
                                                                    cover_resized: cover_resized)
           end
  end

  def add_trending(liked_ids)
    return [] unless SiteSetting.enable_trending_section

    Content.trending(15)
           .pluck(:id, :title, :description, :banner, :banner_resized, :cover_resized)
           .map do |id, title, desc, banner, banner_resized, cover_resized|
             build_content_hash(id, title, desc, banner, liked_ids, banner_resized: banner_resized,
                                                                    cover_resized: cover_resized)
           end
  end

  def add_continue_watching(liked_ids)
    return [] unless current_profile.present?

    ContinueWatching
      .select("DISTINCT ON (content_id) continue_watchings.*, contents.title, contents.description, contents.banner, contents.banner_resized, contents.cover_resized")
      .joins(:content)
      .where(profile_id: current_profile.id)
      .order("content_id, last_watched_at DESC")
      .limit(20)
      .includes(:content, :episode)
      .map do |cw|
        build_content_hash(
          cw.content.id, cw.content.title, cw.content.description, cw.content.banner, liked_ids,
          banner_resized: cw.content.banner_resized, cover_resized: cw.content.cover_resized
        ).merge(
          progress: cw.progress,
          duration: cw.duration,
          last_watched_at: cw.last_watched_at,
          episode: cw.episode&.as_json(except: %i[created_at updated_at])
        )
      end
      .sort_by { |cw| -cw[:last_watched_at].to_i }
  end

  def build_content_sections(liked_ids)
    sections = []

    continue_watching = add_continue_watching(liked_ids)
    if continue_watching.present?
      sections << { title: I18n.t("js.home.continue_watching"), content: continue_watching }
    end

    recommended = add_recommended_based_on_liked(liked_ids)
    if recommended[:content].present?
      sections << { title: I18n.t("js.home.because_you_liked", title: recommended[:title]),
                    content: recommended[:content].shuffle }
    elsif liked_ids.empty?
      maybe_like = add_most_viewed(liked_ids)
      if maybe_like.present?
        sections << { title: I18n.t("js.home.you_might_like"), content: maybe_like }
      end
    end

    new_this_week = add_new_this_week(liked_ids)
    if new_this_week.present?
      sections << { title: I18n.t("js.home.new_this_week"), content: new_this_week }
    end

    trending = add_trending(liked_ids)
    if trending.present?
      sections << { title: I18n.t("js.home.trending"), content: trending }
    end

    added_recently = add_added_recently(liked_ids)
    if added_recently.present?
      sections << { title: I18n.t("js.home.added_recently"), content: added_recently }
    end

    most_viewed = add_most_viewed(liked_ids)
    if most_viewed.present?
      sections << { title: I18n.t("js.home.most_viewed"), content: most_viewed }
    end

    most_liked = add_most_liked(liked_ids)
    if most_liked.present?
      sections << { title: I18n.t("js.home.most_liked"), content: most_liked }
    end

    by_genre = add_by_genre(liked_ids)
    sections.concat(by_genre) if by_genre.present?

    if (top_10 = top_10_content_by_country)&.present?
      sections << { title: I18n.t("js.home.top_10_content_by_country", country: top_10[:country]),
                    content: top_10[:content] }
    end

    sections
  end

  def inject_trailers_into_content(items)
    return if items.blank?

    content_ids = items.map { |c| c[:id] }
    trailer_map = load_trailer_map(content_ids)

    items.each do |item|
      inject_trailer(item, trailer_map)
    end
  end

  def inject_trailers_into_sections(sections)
    return if sections.blank?

    content_ids = sections.flat_map { |s| s[:content].map { |c| c[:id] } }.uniq
    trailer_map = load_trailer_map(content_ids)

    sections.each do |section|
      section[:content].each do |item|
        inject_trailer(item, trailer_map)
      end
    end
  end

  def load_trailer_map(content_ids)
    return {} if content_ids.blank?

    VideoSource.where(trailer: true, videoable_id: content_ids, videoable_type: "Content")
               .pluck(:videoable_id, :url, :format, :quality)
               .group_by(&:first)
  end

  def inject_trailer(item, trailer_map)
    sources = (trailer_map[item[:id]] || []).map { |_, url, fmt, qlt| { url: url, format: fmt, quality: qlt } }
    return if sources.empty?

    item[:trailer_sources] = sources
    item[:trailer_mime_type] = infer_trailer_mime_type(sources.first[:url], sources)
  end

  def build_content_hash(id, title, description, banner, liked_ids, banner_resized: nil, cover_resized: nil)
    {
      id: id,
      title: title,
      description: description,
      banner: banner,
      banner_resized: banner_resized,
      cover_resized: cover_resized,
      liked: liked_ids.include?(id)
    }
  end

  def top_10_content_by_country
    @top_10_content_by_country ||= begin
      ip_address = get_ip_address
      return nil unless ip_address

      ip_info = IpInfo.lookup(ip_address)
      content = CinelarTV.cache.read("top_10_content_#{ip_info[:country_code]}")

      { country: ip_info[:country], content: content } if content.present?
    end
  end

  def get_ip_address
    @get_ip_address ||= request.remote_ip
  end
end
