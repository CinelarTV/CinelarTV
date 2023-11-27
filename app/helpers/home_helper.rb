# frozen_string_literal: true

module HomeHelper
  def homepage_data
    liked_contents_ids = liked_content_ids

    @homepage_data = {
      banner_content: load_banner_content(liked_contents_ids),
      content: [],
    }

    add_recommended_based_on_liked(liked_contents_ids)
    add_continue_watching(liked_contents_ids)
    add_added_recently(liked_contents_ids)

    @homepage_data
  end

  private

  def liked_content_ids
    current_profile&.liked_contents&.pluck(:id) || []
  end

  def load_banner_content(liked_contents_ids)
    Content.where(available: true).where.not(banner: nil).order("RANDOM()").limit(10).map do |content|
      {
        id: content.id,
        title: content.title,
        description: content.description,
        banner: content.banner,
        liked: liked_contents_ids.include?(content.id),
      }
    end
  end

  def add_added_recently(liked_contents_ids)
    added_recently = Content.added_recently.limit(15).pluck(:id, :title, :description, :banner).map do |content|
      {
        id: content.id,
        title: content.title,
        description: content.description,
        banner: content.banner,
        liked: liked_contents_ids.include?(content.id),
      }
    end

    @homepage_data[:content].insert(
      1,
      {
        title: I18n.t("js.home.added_recently"),
        content: added_recently.presence,
      }
    ) if added_recently.present?
  end

  def add_recommended_based_on_liked(liked_contents_ids)
    random_liked = Content.find_by(id: liked_contents_ids.sample)

    if random_liked.present?
      recommended_based_on_liked = random_liked.similar_items.map do |content|
        {
          id: content.id,
          title: content.title,
          description: content.description,
          banner: content.banner,
          liked: liked_contents_ids.include?(content.id),
        }
      end

      @homepage_data[:content].insert(
        0,
        {
          title: I18n.t("js.home.because_you_liked", title: random_liked.title),
          content: recommended_based_on_liked.shuffle,
        }
      )
    end
  end

  def add_continue_watching(liked_contents_ids)
    return unless current_profile.present?

    continue_watching = ContinueWatching
      .select("DISTINCT ON (content_id) continue_watchings.*, contents.title, contents.description, contents.banner")
      .joins(:content)
      .where(profile_id: current_profile.id)
      .order("content_id, last_watched_at DESC")
      .limit(20)
      .map do |cw|
      content = cw.content
      episode = cw.episode

      {
        id: content.id,
        title: content.title,
        description: content.description,
        banner: content.banner,
        liked: liked_contents_ids.include?(content.id),
        progress: cw.progress,
        duration: cw.duration,
        last_watched_at: cw.last_watched_at,
        episode: episode&.as_json(except: %i[created_at updated_at]),
      }
    end

    if continue_watching.present?
      # Now, sort the complete list by last_watched_at in descending order
      continue_watching.sort_by! { |cw| cw[:last_watched_at] }.reverse!

      @homepage_data[:content].insert(
        0,
        {
          title: I18n.t("js.home.continue_watching"),
          content: continue_watching,
        }
      )
    end
  end

  def insert_continue_watching(continue_watching, liked_contents_ids)
    if continue_watching.present?
      @homepage_data[:content].insert(
        0,
        {
          title: I18n.t("js.home.continue_watching"),
          content: continue_watching,
        }
      )
    end
  end

  def insert_top_10_content_by_country
    ip_address = get_ip_address

    if ip_address.present?
      ip_info = IpInfo.lookup(ip_address)
      top_10_content = CinelarTV.cache.read("top_10_content_#{ip_info[:country_code]}")

      if top_10_content.present?
        @homepage_data[:content].insert(
          1,
          {
            title: I18n.t("js.home.top_10_content_by_country", country: ip_info[:country]),
            content: top_10_content,
          }
        )
      end
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
