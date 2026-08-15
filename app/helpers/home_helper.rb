# frozen_string_literal: true

module HomeHelper
  def homepage_data
    @homepage_data ||= begin
      ids_set = liked_content_ids
      include_trailers = params[:include_trailers] == "true"

      banner = load_banner_content(ids_set)

      personalized = build_personalized_sections(ids_set)
      global = build_global_sections

      sections = personalized + global

      inject_trailers(banner, sections) if include_trailers

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
                      .includes(:image_variants)
                      .order("RANDOM()")
                      .limit(10)

    content_ids = contents.map(&:id)

    trailer_sources = VideoSource.where(trailer: true, videoable_id: content_ids, videoable_type: "Content")
                                 .pluck(:videoable_id, :url, :format, :quality)
                                 .group_by(&:first)

    contents.map do |content|
      sources = (trailer_sources[content.id] || []).map { |_, url, fmt, qlt| { url: url, format: fmt, quality: qlt } }

      {
        id: content.id,
        title: content.title,
        description: content.description,
        banner: content.banner,
        trailer_url: content.trailer_url,
        trailer_sources: sources,
        trailer_mime_type: infer_trailer_mime_type(content.trailer_url, sources),
        content_type: content.content_type,
        year: content.year,
        liked: liked_ids.include?(content.id),
        images: {
          poster: content.image_variants_for("poster", only: allowed_variants),
          backdrop: content.image_variants_for("backdrop", only: allowed_variants)
        }
      }
    end
  end

  private

  def allowed_variants
    @allowed_variants ||= begin
      raw = params[:img_variants]
      return %w[original medium large] if raw.blank?

      allowed = raw.split(",").map(&:strip).reject(&:blank?)
      allowed.presence || %w[original medium large]
    end
  end

  def liked_content_ids
    return @liked_content_ids if defined?(@liked_content_ids)
    return @liked_content_ids = Set.new unless current_profile

    @liked_content_ids = Set.new(
      CinelarTV.cache.fetch("profile_liked_ids/#{current_profile.id}", expires_in: 30.minutes) do
        current_profile.liked_contents.pluck(:id)
      end
    )
  end

  def disliked_content_ids
    return @disliked_content_ids if defined?(@disliked_content_ids)
    return @disliked_content_ids = Set.new unless current_profile

    @disliked_content_ids = Set.new(
      CinelarTV.cache.fetch("profile_disliked_ids/#{current_profile.id}", expires_in: 30.minutes) do
        current_profile.disliked_contents.pluck(:id)
      end
    )
  end

  def infer_trailer_mime_type(url, _sources)
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

  # Genera el peso de cada categoría según la frecuencia en los 'likes' del perfil
  def user_category_weights(liked_ids)
    return {} if liked_ids.blank?

    CinelarTV.cache.fetch("profile_category_weights/#{current_profile.id}", expires_in: 1.hour) do
      ContentCategory.where(content_id: liked_ids.to_a)
                      .group(:category_id)
                      .count
    end
  end

  def personalized_banner_content(liked_ids, profile)
    # Bucket de rotación (cambia la semilla del caché cada 3 horas para evitar monotonía)
    rotation_bucket = Time.zone.now.hour / 3
    liked_hash = Digest::MD5.hexdigest(liked_ids.sort.join(","))
    disliked_hash = Digest::MD5.hexdigest(disliked_content_ids.sort.join(","))
    cache_key = "homepage/banner_v2/#{profile.id}/#{liked_hash}/#{disliked_hash}/rot_#{rotation_bucket}"

    CinelarTV.cache.fetch(cache_key, expires_in: 15.minutes) do
      category_weights = user_category_weights(liked_ids)

      # 1. Obtenemos un pool amplio (30 items) evaluados según la nueva fórmula de puntaje
      candidate_ids = Content.where(available: true)
                             .where.not(banner: nil)
                             .where.not(id: disliked_content_ids.to_a)
                             .left_joins(:content_analytic)
                             .order(Arel.sql(banner_score_sql(category_weights, profile.id)))
                             .limit(30)
                             .pluck(:id)

      # 2. Aplicamos diversificación por géneros sobre los candidatos seleccionados
      selected_ids = apply_banner_diversity(candidate_ids, limit: 10)

      contents_by_id = Content.where(id: selected_ids).includes(:image_variants).index_by(&:id)
      selected_ids.filter_map { |id| contents_by_id[id] }
                  .map { |c| content_to_hash(c, allowed_variants: allowed_variants) }
    end
  end

  def random_banner_content(_liked_ids)
    profile_id = current_profile&.id
    quoted_pid = ActiveRecord::Base.connection.quote(profile_id)

    order_sql = if profile_id
                  "CASE WHEN EXISTS (SELECT 1 FROM dislikes d WHERE d.content_id = contents.id AND d.profile_id = #{quoted_pid}) THEN 1 ELSE 0 END, RANDOM()"
                else
                  "RANDOM()"
                end

    content_ids = Content.where(available: true)
                         .where.not(banner: nil)
                         .order(Arel.sql(order_sql))
                         .limit(10)
                         .pluck(:id)

    contents_by_id = Content.where(id: content_ids).includes(:image_variants).index_by(&:id)
    content_ids.filter_map { |id| contents_by_id[id] }
               .map { |c| content_to_hash(c, allowed_variants: allowed_variants) }
  end

  def banner_score_sql(category_weights, profile_id)
    connection = ActiveRecord::Base.connection
    quoted_pid = connection.quote(profile_id)

    scores = []

    # 1. Contenido en "Continuar viendo" (en progreso)
    scores << <<~SQL.squish
      CASE
        WHEN EXISTS (
          SELECT 1 FROM continue_watchings cw
          WHERE cw.content_id = contents.id
            AND cw.profile_id = #{quoted_pid}
            AND cw.finished = FALSE
            AND cw.progress > 0
        ) THEN 40 ELSE 0
      END
    SQL

    # 2. Ponderación dinámica de géneros/categorías favoritas
    if category_weights.any?
      weight_cases = category_weights.map do |cat_id, count|
        "WHEN cc.category_id = #{connection.quote(cat_id)} THEN #{[count * 10, 50].min}"
      end.join(" ")

      scores << <<~SQL.squish
        COALESCE((
          SELECT SUM(CASE #{weight_cases} ELSE 0 END)
          FROM content_categories cc
          WHERE cc.content_id = contents.id
        ), 0)
      SQL
    end

    # 3. Coincidencia de elenco / cast preferido
    scores << <<~SQL.squish
      LEAST(40, (
        SELECT COUNT(*) * 8
        FROM cast_members cm
        WHERE cm.content_id = contents.id
          AND cm.person_id IN (
            SELECT DISTINCT cm2.person_id
            FROM likes l
            JOIN cast_members cm2 ON cm2.content_id = l.content_id
            WHERE l.profile_id = #{quoted_pid}
          )
      ))
    SQL

    # 4. Frescura del contenido (bonus si se agregó recientemente)
    scores << <<~SQL.squish
      GREATEST(0, 30 - (EXTRACT(EPOCH FROM (NOW() - contents.created_at)) / 86400.0))
    SQL

    # 5. Popularidad general logarítmica
    scores << "LN(GREATEST(COALESCE(content_analytics.total_views, 1), 1)) * 4"

    # 6. Penalización fuerte a lo ya visto del todo (evita repetición innecesaria)
    scores << <<~SQL.squish
      CASE
        WHEN EXISTS (
          SELECT 1 FROM continue_watchings cw
          WHERE cw.content_id = contents.id
            AND cw.profile_id = #{quoted_pid}
            AND cw.finished = TRUE
        ) THEN -200 ELSE 0
      END
    SQL

    # 7. Factor estocástico para rotación (variación de puntaje)
    scores << "RANDOM() * 25"

    scores.join(" + ")
  end

  def apply_banner_diversity(candidate_ids, limit: 10)
    return candidate_ids.first(limit) if candidate_ids.blank?

    categories_by_content = ContentCategory.where(content_id: candidate_ids)
                                           .pluck(:content_id, :category_id)
                                           .to_h

    category_counts = Hash.new(0)
    selected = []

    candidate_ids.each do |id|
      cat_id = categories_by_content[id] || 0
      if category_counts[cat_id] < 3 || selected.size < 5
        selected << id
        category_counts[cat_id] += 1
      end
      break if selected.size == limit
    end

    if selected.size < limit
      remaining = candidate_ids - selected
      selected.concat(remaining.first(limit - selected.size))
    end

    selected
  end

  def add_added_recently(liked_ids)
    Content.added_recently.includes(:image_variants).limit(15).map { |c| content_to_hash(c, allowed_variants: allowed_variants) }
  end

  def add_recommended_based_on_liked(liked_ids)
    return { title: nil, content: [] } if liked_ids.empty?

    random_liked = Content.find_by(id: liked_ids.to_a.sample)
    return { title: nil, content: [] } unless random_liked

    similar_content = random_liked.similar_items
                                  .reject { |c| c.id == random_liked.id || disliked_content_ids.include?(c.id) }

    content_ids = similar_content.map(&:id)
    all_variants = ImageVariant.where(imageable_type: "Content", imageable_id: content_ids).to_a
    variants_by_content = all_variants.group_by(&:imageable_id)

    similar_content.each do |c|
      c.association(:image_variants).target = variants_by_content[c.id] || []
    end

    { title: random_liked.title, content: similar_content.map { |c| content_to_hash(c, allowed_variants: allowed_variants) } }
  end

  def add_most_viewed(liked_ids)
    return [] unless SiteSetting.enable_most_viewed_section

    Content.most_viewed(15).includes(:image_variants).map { |c| content_to_hash(c, allowed_variants: allowed_variants) }
  end

  def add_most_liked(liked_ids)
    return [] unless SiteSetting.enable_most_liked_section

    Content.most_liked(15).includes(:image_variants).map { |c| content_to_hash(c, allowed_variants: allowed_variants) }
  end

  def add_by_genre(liked_ids)
    return [] unless SiteSetting.enable_content_by_genre

    per_page = 10

    categories = Category
      .joins(:contents)
      .where(contents: { available: true })
      .group("categories.id")
      .having("COUNT(contents.id) >= 3")
      .order(Arel.sql("COUNT(contents.id) DESC"))
      .limit(6)
      .to_a

    return [] if categories.empty?

    category_ids = categories.map(&:id)

    content_ids_by_category = ContentCategory
      .where(category_id: category_ids)
      .joins(:content)
      .where(contents: { available: true })
      .pluck(:category_id, :content_id)
      .group_by(&:first)
      .transform_values { |pairs| pairs.map(&:last) }

    shown_ids = Set.new
    selected_ids_by_category = {}

    categories.each do |category|
      ids = content_ids_by_category[category.id]
      next if ids.blank?

      selected = ids.shuffle.reject { |id| shown_ids.include?(id) }.first(per_page)
      next if selected.blank?

      shown_ids.merge(selected)
      selected_ids_by_category[category.id] = selected
    end

    return [] if selected_ids_by_category.empty?

    contents_by_id = Content.where(id: shown_ids.to_a)
                            .includes(:image_variants)
                            .index_by(&:id)

    selected_ids_by_category.filter_map do |category_id, ids|
      content_list = ids.filter_map { |id| contents_by_id[id] }
                        .map { |c| content_to_hash(c, allowed_variants: allowed_variants) }
      next if content_list.blank?

      category = categories.find { |c| c.id == category_id }
      { title: category.name, content: content_list }
    end
  end

  def add_new_this_week(liked_ids)
    Content.new_this_week.includes(:image_variants).map { |c| content_to_hash(c, allowed_variants: allowed_variants) }
  end

  def add_trending(liked_ids)
    return [] unless SiteSetting.enable_trending_section

    Content.trending(15).includes(:image_variants).map { |c| content_to_hash(c, allowed_variants: allowed_variants) }
  end

  def add_continue_watching(liked_ids)
    return [] unless current_profile.present?

    ContinueWatching
      .select("DISTINCT ON (content_id) continue_watchings.*, contents.title, contents.description, contents.banner")
      .joins(:content)
      .where(profile_id: current_profile.id)
      .where(finished: false)
      .order("content_id, last_watched_at DESC")
      .limit(20)
      .includes(content: :image_variants, episode: nil)
      .map do |cw|
        content = cw.content
        episode_key = cw.episode_id.presence || "movie"
        redis_data = CinelarTV.cache.read("progress/#{cw.profile_id}/#{cw.content_id}/#{episode_key}")

        last_watched = redis_data&.dig(:last_watched_at) || cw.last_watched_at

        content_to_hash(content, allowed_variants: allowed_variants).merge(
          progress: redis_data&.dig(:progress) || cw.progress,
          duration: redis_data&.dig(:duration) || cw.duration,
          last_watched_at: last_watched,
          episode: cw.episode&.as_json(except: %i[created_at updated_at])
        )
      end
      .sort_by { |cw| -cw[:last_watched_at].to_i }
  end

  def build_personalized_sections(liked_ids)
    return [] unless current_profile

    sections = []

    continue_watching = add_continue_watching(liked_ids)
    if continue_watching.present?
      sections << { title: I18n.t("js.home.continue_watching"), content: continue_watching }
    end

    liked_hash = Digest::MD5.hexdigest(liked_ids.sort.join(","))
    disliked_hash = Digest::MD5.hexdigest(disliked_content_ids.sort.join(","))
    cache_key = "homepage/personal/#{current_profile.id}/#{liked_hash}/#{disliked_hash}"

    recommended_sections = CinelarTV.cache.fetch(cache_key, expires_in: 5.minutes) do
      result = []

      recommended = add_recommended_based_on_liked(liked_ids)
      if recommended[:content].present?
        result << { title: I18n.t("js.home.because_you_liked", title: recommended[:title]),
                    content: recommended[:content].shuffle }
      elsif liked_ids.empty?
        maybe_like = add_most_viewed(liked_ids)
        if maybe_like.present?
          result << { title: I18n.t("js.home.you_might_like"), content: maybe_like }
        end
      end

      result
    end

    sections + recommended_sections
  end

  def build_global_sections
    sections = CinelarTV.cache.fetch("homepage/global_sections", expires_in: 15.minutes) do
      result = []

      new_this_week = add_new_this_week(Set.new)
      if new_this_week.present?
        result << { title: I18n.t("js.home.new_this_week"), content: new_this_week }
      end

      trending = add_trending(Set.new)
      if trending.present?
        result << { title: I18n.t("js.home.trending"), content: trending }
      end

      added_recently = add_added_recently(Set.new)
      if added_recently.present?
        result << { title: I18n.t("js.home.added_recently"), content: added_recently }
      end

      most_viewed = add_most_viewed(Set.new)
      if most_viewed.present?
        result << { title: I18n.t("js.home.most_viewed"), content: most_viewed }
      end

      most_liked = add_most_liked(Set.new)
      if most_liked.present?
        result << { title: I18n.t("js.home.most_liked"), content: most_liked }
      end

      by_genre = add_by_genre(Set.new)
      result.concat(by_genre) if by_genre.present?

      result
    end

    if (top_10 = top_10_content_by_country)&.present?
      sections << { title: I18n.t("js.home.top_10_content_by_country", country: top_10[:country]),
                    content: top_10[:content] }
    end

    sections
  end

  def inject_trailers(banner, sections)
    content_ids = (banner || []).map { |c| c[:id] } +
                  sections.flat_map { |s| s[:content].map { |c| c[:id] } }

    return if content_ids.empty?

    trailer_map = load_trailer_map(content_ids.uniq)
    return if trailer_map.empty?

    (banner || []).each { |item| inject_trailer(item, trailer_map) }
    sections.each do |section|
      section[:content].each { |item| inject_trailer(item, trailer_map) }
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

  def content_to_hash(content, allowed_variants: nil)
    poster = content.image_variants_for("poster", only: allowed_variants)
    backdrop = content.image_variants_for("backdrop", only: allowed_variants)
    logo = content.image_variants_for("logo", only: allowed_variants)

    {
      id: content.id,
      title: content.title,
      description: content.description,
      banner: backdrop.dig("original", "webp"),
      poster: poster.dig("original", "webp"),
      banner_resized: backdrop.dig("medium", "webp"),
      cover_resized: poster.dig("medium", "webp"),
      liked: liked_content_ids.include?(content.id),
      disliked: disliked_content_ids.include?(content.id),
      images: {
        poster: poster,
        backdrop: backdrop,
        logo: logo
      }
    }
  end

  def top_10_content_by_country
    @top_10_content_by_country ||= begin
      ip_address = get_ip_address
      return nil unless ip_address

      ip_info = IpInfo.lookup(ip_address)
      return nil unless ip_info && ip_info[:country_code].present?

      content = CinelarTV.cache.read("top_10_content_#{ip_info[:country_code]}")

      { country: ip_info[:country], content: content } if content.present?
    end
  rescue StandardError => e
    Rails.logger.warn("top_10_content_by_country failed: #{e.message}")
    nil
  end

  def get_ip_address
    @get_ip_address ||= request.headers["CF-Connecting-IP"] || request.remote_ip
  end
end