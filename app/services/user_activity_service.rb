# frozen_string_literal: true

class UserActivityService
  def initialize(user, page: 1, per_page: 20, activity_type: nil, profile_id: nil)
    @user = user
    @page = [page.to_i, 1].max
    @per_page = [per_page.to_i, 1].max.clamp(1, 100)
    @activity_type = activity_type.presence || "all"
    @profile_id = profile_id.presence
  end

  def call
    profile_scope = @user.profiles
    if @profile_id.present?
      target_profile = profile_scope.find_by(id: @profile_id)
      @profile_ids = target_profile ? [target_profile.id] : []
    else
      @profile_ids = profile_scope.pluck(:id)
    end

    counts = calculate_counts
    items, total = fetch_items(counts)

    {
      data: items,
      meta: {
        total: total,
        page: @page,
        per_page: @per_page,
        total_pages: total.zero? ? 1 : (total.to_f / @per_page).ceil,
        counts: counts,
        profiles: @user.profiles.map { |p| { id: p.id, name: p.name, avatar_id: p.avatar_id } }
      }
    }
  end

  private

  def calculate_counts
    return empty_counts if @profile_ids.empty? && @profile_id.present?

    reproductions = Reproduction.where(profile_id: @profile_ids).count
    likes = Like.where(profile_id: @profile_ids).count
    dislikes = Dislike.where(profile_id: @profile_ids).count
    billing = @profile_id.blank? ? (Subscription.where(user_id: @user.id).count + Payment.where(user_id: @user.id).count) : 0
    security = @profile_id.blank? ? AuditLog.where("target_user_id = :uid OR user_id = :uid", uid: @user.id).count : 0

    {
      all: reproductions + likes + dislikes + billing + security,
      reproduction: reproductions,
      like: likes,
      dislike: dislikes,
      billing: billing,
      security: security
    }
  end

  def empty_counts
    { all: 0, reproduction: 0, like: 0, dislike: 0, billing: 0, security: 0 }
  end

  def fetch_items(counts)
    return [[], 0] if @profile_ids.empty? && @profile_id.present?

    offset = (@page - 1) * @per_page

    case @activity_type
    when "reproduction"
      records = Reproduction.where(profile_id: @profile_ids)
                            .includes(:content, :profile, :episode)
                            .order(Arel.sql("COALESCE(played_at, created_at) DESC"))
                            .offset(offset)
                            .limit(@per_page)
      [records.map { |r| reproduction_to_activity(r) }, counts[:reproduction]]

    when "like"
      records = Like.where(profile_id: @profile_ids)
                    .includes(:content, :profile)
                    .order(created_at: :desc)
                    .offset(offset)
                    .limit(@per_page)
      episode_map = batch_episode_map(records.map { |l| [l.profile_id, l.content_id] })
      [records.map { |l| like_to_activity(l, episode: episode_map[[l.profile_id, l.content_id]]) }, counts[:like]]

    when "dislike"
      records = Dislike.where(profile_id: @profile_ids)
                       .includes(:content, :profile)
                       .order(created_at: :desc)
                       .offset(offset)
                       .limit(@per_page)
      episode_map = batch_episode_map(records.map { |d| [d.profile_id, d.content_id] })
      [records.map { |d| dislike_to_activity(d, episode: episode_map[[d.profile_id, d.content_id]]) }, counts[:dislike]]

    when "billing"
      return [[], 0] if @profile_id.present?

      items = fetch_billing_items(limit: offset + @per_page)
      paginated = items.slice(offset, @per_page) || []
      [paginated, counts[:billing]]

    when "security"
      return [[], 0] if @profile_id.present?

      records = AuditLog.where("target_user_id = :uid OR user_id = :uid", uid: @user.id)
                        .includes(:user, :target_user)
                        .order(created_at: :desc)
                        .offset(offset)
                        .limit(@per_page)
      [records.map { |log| audit_log_to_activity(log) }, counts[:security]]

    else # "all"
      fetch_all_items(offset: offset, limit: @per_page, total: counts[:all])
    end
  end

  def fetch_all_items(offset:, limit:, total:)
    fetch_limit = offset + limit

    reproductions = Reproduction.where(profile_id: @profile_ids)
                                .includes(:content, :profile, :episode)
                                .order(Arel.sql("COALESCE(played_at, created_at) DESC"))
                                .limit(fetch_limit)

    likes = Like.where(profile_id: @profile_ids)
                .includes(:content, :profile)
                .order(created_at: :desc)
                .limit(fetch_limit)

    dislikes = Dislike.where(profile_id: @profile_ids)
                      .includes(:content, :profile)
                      .order(created_at: :desc)
                      .limit(fetch_limit)

    all_pairs = (likes.map { |l| [l.profile_id, l.content_id] } +
                 dislikes.map { |d| [d.profile_id, d.content_id] }).uniq

    episode_map = batch_episode_map(all_pairs)

    reproductions = reproductions.map { |r| reproduction_to_activity(r) }
    likes = likes.map { |l| like_to_activity(l, episode: episode_map[[l.profile_id, l.content_id]]) }
    dislikes = dislikes.map { |d| dislike_to_activity(d, episode: episode_map[[d.profile_id, d.content_id]]) }

    billing = @profile_id.blank? ? fetch_billing_items(limit: fetch_limit) : []
    security = @profile_id.blank? ? fetch_security_items(limit: fetch_limit) : []

    combined = (reproductions + likes + dislikes + billing + security)
               .sort_by { |item| Time.zone.parse(item[:timestamp].to_s) || Time.current }
               .reverse

    paginated = combined.slice(offset, limit) || []
    [paginated, total]
  end

  def fetch_billing_items(limit:)
    subs = Subscription.where(user_id: @user.id)
                       .order(created_at: :desc)
                       .limit(limit)
                       .map { |s| subscription_to_activity(s) }

    payments = Payment.where(user_id: @user.id)
                      .order(created_at: :desc)
                      .limit(limit)
                      .map { |p| payment_to_activity(p) }

    (subs + payments).sort_by { |i| Time.zone.parse(i[:timestamp].to_s) || Time.current }.reverse.first(limit)
  end

  def fetch_security_items(limit:)
    AuditLog.where("target_user_id = :uid OR user_id = :uid", uid: @user.id)
            .includes(:user, :target_user)
            .order(created_at: :desc)
            .limit(limit)
            .map { |log| audit_log_to_activity(log) }
  end

  def reproduction_to_activity(r)
    {
      id: "reproduction-#{r.id}",
      type: "reproduction",
      action: "played",
      action_label: "Reprodujo",
      timestamp: (r.played_at || r.created_at)&.iso8601,
      profile: profile_payload(r.profile),
      content: content_payload(r.content),
      episode: episode_payload(r.episode),
      metadata: {
        country_code: r.country_code
      }
    }
  end

  def like_to_activity(l, episode: nil)
    {
      id: "like-#{l.id}",
      type: "like",
      action: "liked",
      action_label: "Le dio me gusta",
      timestamp: l.created_at&.iso8601,
      profile: profile_payload(l.profile),
      content: content_payload(l.content),
      episode: episode_payload(episode),
      metadata: {}
    }
  end

  def dislike_to_activity(d, episode: nil)
    {
      id: "dislike-#{d.id}",
      type: "dislike",
      action: "disliked",
      action_label: "Le dio no me gusta",
      timestamp: d.created_at&.iso8601,
      profile: profile_payload(d.profile),
      content: content_payload(d.content),
      episode: episode_payload(episode),
      metadata: {}
    }
  end

  def subscription_to_activity(s)
    {
      id: "subscription-#{s.id}",
      type: "billing",
      action: "subscription",
      action_label: "Suscripción #{s.provider.to_s.titleize}",
      timestamp: s.created_at&.iso8601,
      profile: nil,
      content: nil,
      episode: nil,
      metadata: {
        provider: s.provider,
        status: s.status
      }
    }
  end

  def payment_to_activity(p)
    {
      id: "payment-#{p.id}",
      type: "billing",
      action: "payment",
      action_label: "Pago de #{p.amount} #{p.currency}",
      timestamp: p.created_at&.iso8601,
      profile: nil,
      content: nil,
      episode: nil,
      metadata: {
        amount: p.amount,
        currency: p.currency,
        status: p.status
      }
    }
  end

  def audit_log_to_activity(log)
    actor_name = log.user&.username || "Sistema"
    {
      id: "audit-#{log.id}",
      type: "security",
      action: "audit_log",
      action_label: log.human_action || "Acción administrativa",
      timestamp: log.created_at&.iso8601,
      profile: nil,
      content: nil,
      episode: nil,
      metadata: {
        subject: log.subject,
        details: log.details,
        ip_address: log.ip_address,
        actor: actor_name,
        target_user: log.target_user&.username
      }
    }
  end

  def profile_payload(profile)
    return nil unless profile

    {
      id: profile.id,
      name: profile.name,
      avatar_id: profile.avatar_id
    }
  end

  def content_payload(content)
    return nil unless content

    {
      id: content.id,
      title: content.title,
      content_type: content.content_type,
      banner: content.banner,
      cover: content.cover
    }
  end

  def batch_episode_map(pairs)
    return {} if pairs.empty?

    unique_pairs = pairs.uniq
    profile_ids = unique_pairs.map(&:first).uniq
    content_ids = unique_pairs.map(&:last).uniq

    all_sessions = WatchSession.where(profile_id: profile_ids, content_id: content_ids)
                               .where.not(episode_id: nil)
                               .includes(episode: :season)
                               .order(Arel.sql("COALESCE(ended_at, started_at) DESC"))

    by_pair = {}
    all_sessions.each do |ws|
      key = [ws.profile_id, ws.content_id]
      (by_pair[key] ||= []) << ws
    end

    result = {}
    by_pair.each do |key, sessions|
      result[key] = sessions.first&.episode
    end
    result
  end

  def episode_payload(episode)
    return nil unless episode

    season = episode.season
    {
      id: episode.id,
      title: episode.title,
      position: episode.position,
      season_number: season&.position || 0,
      thumbnail: episode.thumbnail,
      images: {
        episode_thumbnail: episode.image_variants_for("episode_thumbnail")
      }
    }
  end
end
