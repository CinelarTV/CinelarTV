# frozen_string_literal: true

module HomeHelper
  def homepage_data
    liked_contents_ids = liked_content_ids

    @homepage_data = {
      banner_content: load_banner_content(liked_contents_ids),
      content: build_content_sections(liked_contents_ids)
    }

    @homepage_data
  end

  private

  def liked_content_ids
    current_profile&.liked_contents&.pluck(:id) || []
  end

  def load_banner_content(liked_contents_ids)
    Content.where(available: true)
           .where.not(banner: nil)
           .order("RANDOM()")
           .limit(10)
           .map { |content| content_data(content, liked_contents_ids) }
  end

  def add_added_recently(liked_contents_ids)
    Content.added_recently
           .limit(15)
           .map { |content| content_data(content, liked_contents_ids) }
  end

  def add_recommended_based_on_liked(liked_contents_ids)
    if (random_liked = Content.find_by(id: liked_contents_ids.sample))
      random_liked.similar_items.map { |content| content_data(content, liked_contents_ids) }
    end
  end

  def add_continue_watching(liked_contents_ids)
    return unless current_profile.present?

    ContinueWatching.select("DISTINCT ON (content_id) continue_watchings.*, contents.title, contents.description, contents.banner")
                    .joins(:content)
                    .where(profile_id: current_profile.id)
                    .order("content_id, last_watched_at DESC")
                    .limit(20)
                    .map do |cw|
      content = cw.content
      episode = cw.episode
      content_data(content, liked_contents_ids).merge(
        progress: cw.progress,
        duration: cw.duration,
        last_watched_at: cw.last_watched_at,
        episode: episode&.as_json(except: %i[created_at updated_at])
      )
    end.sort_by { |cw| -cw[:last_watched_at].to_i }
  end

  def build_content_sections(liked_contents_ids)
    sections = []

    # Agrega las secciones en el orden deseado solo si contienen contenido
    if (recommended_content = add_recommended_based_on_liked(liked_contents_ids)).present?
      title = I18n.t("js.home.because_you_liked", title: recommended_content.dig(0, :title))
      sections << { title: title, content: recommended_content.shuffle }
    end

    if (continue_watching = add_continue_watching(liked_contents_ids)).present?
      title = I18n.t("js.home.continue_watching")
      sections << { title: title, content: continue_watching }
    end

    if (added_recently = add_added_recently(liked_contents_ids)).present?
      title = I18n.t("js.home.added_recently")
      sections << { title: title, content: added_recently }
    end

    if (top_10_content = top_10_content_by_country).present?
      title = I18n.t("js.home.top_10_content_by_country", country: top_10_content[:country])
      sections << { title: title, content: top_10_content[:content] }
    end

    sections
  end

  def content_data(content, liked_contents_ids)
    {
      id: content.id,
      title: content.title,
      description: content.description,
      banner: content.banner,
      liked: liked_contents_ids.include?(content.id),
    }
  end

  def top_10_content_by_country
    if (ip_address = get_ip_address)
      ip_info = IpInfo.lookup(ip_address)
      content = CinelarTV.cache.read("top_10_content_#{ip_info[:country_code]}")
      { country: ip_info[:country], content: content } if content.present?
    end
  end

  def get_ip_address
    Rails.env.production? ? request.remote_ip : fetch_ip_address_locally
  end

  def fetch_ip_address_locally
    Net::HTTP.get(URI.parse("http://checkip.amazonaws.com/")).squish
  rescue StandardError => e
    Rails.logger.error "Error fetching IP address: #{e.message}"
    nil
  end
end
