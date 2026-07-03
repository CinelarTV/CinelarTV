# frozen_string_literal: true

module HomeHelper
  def homepage_data
    @homepage_data ||= begin
      ids_set = liked_content_ids

      {
        banner_content: load_banner_content(ids_set),
        content: build_content_sections(ids_set)
      }
    end
  end

  def load_shuffle_recommendations
    liked_ids = liked_content_ids

    Content.where(available: true)
           .where.not(trailer_url: nil)
           .order("RANDOM()")
           .limit(10)
           .pluck(:id, :title, :description, :banner, :trailer_url, :content_type, :year)
           .map do |id, title, desc, banner, trailer_url, content_type, year|
             {
               id: id,
               title: title,
               description: desc,
               banner: banner,
               trailer_url: trailer_url,
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

  def load_banner_content(liked_ids)
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

    Category
      .joins(:contents)
      .where(contents: { available: true })
      .group("categories.id")
      .having("COUNT(contents.id) >= 3")
      .order(Arel.sql("COUNT(contents.id) DESC"))
      .limit(6)
      .map do |category|
        content = Content.by_category_id(category.id, 10)
                         .pluck(:id, :title, :description, :banner, :banner_resized, :cover_resized)
                         .map do |id, title, desc, banner, banner_resized, cover_resized|
                           build_content_hash(id, title, desc, banner, liked_ids, banner_resized: banner_resized,
                                                                                  cover_resized: cover_resized)
                         end
        next if content.empty?

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
    @top_10_content ||= begin
      ip_address = get_ip_address
      return nil unless ip_address

      ip_info = IpInfo.lookup(ip_address)
      content = CinelarTV.cache.read("top_10_content_#{ip_info[:country_code]}")

      { country: ip_info[:country], content: content } if content.present?
    end
  end

  def get_ip_address
    @ip_address ||= request.remote_ip
  end
end
