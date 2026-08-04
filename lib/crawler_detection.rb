# frozen_string_literal: true

module CrawlerDetection
  WAYBACK_MACHINE_URL = "archive.org"

  def self.to_matcher(string)
    return // if string.nil?

    escaped = string.split("|").map { |agent| Regexp.escape(agent) }.join("|")
    Regexp.new(escaped, Regexp::IGNORECASE)
  end

  def self.crawler?(user_agent, via_header = nil)
    if user_agent.nil? || user_agent&.include?(WAYBACK_MACHINE_URL) ||
         via_header&.include?(WAYBACK_MACHINE_URL)
      return true
    end

    @matchers ||= {}

    known_bots =
      (@matchers[SiteSetting.crawler_user_agents] ||= to_matcher(SiteSetting.crawler_user_agents))

    return false unless user_agent.match?(known_bots)

    bypass =
      (@matchers[SiteSetting.crawler_check_bypass_agents] ||= to_matcher(
        SiteSetting.crawler_check_bypass_agents,
      ))

    !user_agent.match?(bypass)
  end

  # Simplified version removing DiscourseIpInfo dependency
  def self.crawler_ip?(ip)
    false # Placeholder: needs custom logic if IP-based detection is required
  end

  def self.show_browser_update?(user_agent)
    return false if SiteSetting.browser_update_user_agents.blank?

    @browser_update_matchers ||= {}
    matcher =
      @browser_update_matchers[SiteSetting.browser_update_user_agents] ||= to_matcher(
        SiteSetting.browser_update_user_agents,
      )
    user_agent.match?(matcher)
  end

  def self.crawler_layout_request?(request)
    return false if request.blank?
    return false if request.user_agent.blank?
    return false if request.media_type.present? && !request.media_type.include?("html")
    return false if %w[json rss].include?(request.params[:format].to_s)

    (SiteSetting.enable_escaped_fragments? && request.params.key?("_escaped_fragment_")) ||
      request.params.key?("print") || show_browser_update?(request.user_agent) ||
      crawler?(request.user_agent, request.headers["HTTP_VIA"])
  end

  def self.allow_crawler?(user_agent)
    if SiteSetting.allowed_crawler_user_agents.blank? &&
         SiteSetting.blocked_crawler_user_agents.blank?
      return true
    end

    @allowlisted_matchers ||= {}
    @blocklisted_matchers ||= {}

    if SiteSetting.allowed_crawler_user_agents.present?
      allowlisted =
        @allowlisted_matchers[SiteSetting.allowed_crawler_user_agents] ||= to_matcher(
          SiteSetting.allowed_crawler_user_agents,
        )
      !user_agent.nil? && user_agent.match?(allowlisted)
    else
      blocklisted =
        @blocklisted_matchers[SiteSetting.blocked_crawler_user_agents] ||= to_matcher(
          SiteSetting.blocked_crawler_user_agents,
        )
      user_agent.nil? || !user_agent.match?(blocklisted)
    end
  end

  def self.is_blocked_crawler?(user_agent)
    crawler?(user_agent) && !allow_crawler?(user_agent)
  end
end
