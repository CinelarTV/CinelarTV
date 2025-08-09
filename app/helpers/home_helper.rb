# frozen_string_literal: true

module HomeHelper
  def homepage_data
    @homepage_data ||= begin
      liked_contents_ids = liked_content_ids
      
      {
        banner_content: load_banner_content(liked_contents_ids),
        content: build_content_sections(liked_contents_ids)
      }
    end
  end

  private

  def liked_content_ids
    @liked_content_ids ||= current_profile&.liked_contents&.pluck(:id) || []
  end

  def load_banner_content(liked_contents_ids)
    Content.where(available: true)
           .where.not(banner: nil)
           .order("RANDOM()")
           .limit(10)
           .pluck(:id, :title, :description, :banner)
           .map { |id, title, description, banner| 
             build_content_hash(id, title, description, banner, liked_contents_ids)
           }
  end

  def add_added_recently(liked_contents_ids)
    Content.added_recently
           .limit(15)
           .pluck(:id, :title, :description, :banner)
           .map { |id, title, description, banner| 
             build_content_hash(id, title, description, banner, liked_contents_ids)
           }
  end

  def add_recommended_based_on_liked(liked_contents_ids)
    return { title: nil, content: [] } if liked_contents_ids.empty?
    
    random_liked_id = liked_contents_ids.sample
    random_liked = Content.find_by(id: random_liked_id)
    return { title: nil, content: [] } unless random_liked
    
    similar_content = random_liked.similar_items
                                 .reject { |c| c.id == random_liked.id }
                                 .map { |content| 
                                   build_content_hash(content.id, content.title, content.description, content.banner, liked_contents_ids)
                                 }
    
    { title: random_liked.title, content: similar_content }
  end

  def add_continue_watching(liked_contents_ids)
    return [] unless current_profile.present?

    continue_watching_data = ContinueWatching
      .select("DISTINCT ON (content_id) continue_watchings.*, contents.title, contents.description, contents.banner")
      .joins(:content)
      .where(profile_id: current_profile.id)
      .order("content_id, last_watched_at DESC")
      .limit(20)
      .includes(:content, :episode)
    
    continue_watching_data.map do |cw|
      content = cw.content
      episode = cw.episode
      
      build_content_hash(content.id, content.title, content.description, content.banner, liked_contents_ids).merge(
        progress: cw.progress,
        duration: cw.duration,
        last_watched_at: cw.last_watched_at,
        episode: episode&.as_json(except: %i[created_at updated_at])
      )
    end.sort_by { |cw| -cw[:last_watched_at].to_i }
  end

  def build_content_sections(liked_contents_ids)
    sections = []
    
    # Usar un hash para almacenar temporalmente los resultados
    section_builders = {
      recommended: -> { add_recommended_based_on_liked(liked_contents_ids) },
      continue_watching: -> { add_continue_watching(liked_contents_ids) },
      added_recently: -> { add_added_recently(liked_contents_ids) },
      top_10: -> { top_10_content_by_country }
    }
    
    # Recomendados
    if (recommended = section_builders[:recommended].call) && recommended[:content].present?
      title = I18n.t("js.home.because_you_liked", title: recommended[:title])
      sections << { title: title, content: recommended[:content].shuffle }
    end

    # Continuar viendo
    if (continue_watching = section_builders[:continue_watching].call).present?
      title = I18n.t("js.home.continue_watching")
      sections << { title: title, content: continue_watching }
    end

    # Agregados recientemente
    if (added_recently = section_builders[:added_recently].call).present?
      title = I18n.t("js.home.added_recently")
      sections << { title: title, content: added_recently }
    end

    # Top 10 por país
    if (top_10_content = section_builders[:top_10].call)&.present?
      title = I18n.t("js.home.top_10_content_by_country", country: top_10_content[:country])
      sections << { title: title, content: top_10_content[:content] }
    end

    sections
  end

  # Método reutilizable para construir el hash de contenido
  def build_content_hash(id, title, description, banner, liked_contents_ids)
    {
      id: id,
      title: title,
      description: description,
      banner: banner,
      liked: liked_contents_ids.include?(id)
    }
  end

  # Método anterior renombrado para mayor claridad
  alias_method :content_data, :build_content_hash

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
    @ip_address ||= Rails.env.production? ? request.remote_ip : fetch_ip_address_locally
  end

  def fetch_ip_address_locally
    @local_ip ||= begin
      Net::HTTP.get(URI.parse("http://checkip.amazonaws.com/")).squish
    rescue StandardError => e
      Rails.logger.error "Error fetching IP address: #{e.message}"
      nil
    end
  end
end