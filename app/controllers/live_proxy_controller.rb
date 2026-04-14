# frozen_string_literal: true

require "cgi"
require "net/http"
require "uri"

class LiveProxyController < ApplicationController
  # This endpoint exists to avoid browser mixed-content blocks when the app runs
  # on HTTPS but upstream HLS streams are served via HTTP. It is intentionally a
  # simple fallback/MVP proxy and is not designed for high-traffic workloads.
  include ActionController::Live

  ALLOWED_STREAM_HOSTS = [
    "provider.com",
    "cdn.provider.com",
  ].freeze

  PASSTHROUGH_HEADERS = %w[
    Content-Type
    Cache-Control
    Content-Length
    Content-Range
    Accept-Ranges
  ].freeze

  HLS_CONTENT_TYPES = %w[
    application/vnd.apple.mpegurl
    application/x-mpegURL
    audio/mpegurl
    audio/x-mpegurl
  ].freeze

  REDIRECT_LIMIT = 3
  MAX_CONCURRENT_PROXY_REQUESTS = ENV.fetch("CINELAR_LIVE_PROXY_MAX_CONCURRENT", 40).to_i

  @proxy_requests_count = 0
  @proxy_requests_mutex = Mutex.new

  class << self
    attr_accessor :proxy_requests_count
    attr_reader :proxy_requests_mutex
  end

  before_action :authenticate_user!
  before_action :check_live_tv_enabled
  around_action :silence_proxy_logs
  around_action :enforce_proxy_concurrency_limit

  def stream
    upstream_uri = parse_upstream_uri(params[:url])
    return if performed?

    unless allowed_stream_host?(upstream_uri.host)
      render json: { error: "Stream host is not allowed" }, status: :forbidden
      return
    end

    proxy_upstream(upstream_uri)
  rescue IOError, Errno::EPIPE
    # Client disconnected while streaming.
  rescue StandardError => e
    Rails.logger.error("LiveProxyController error: #{e.class} - #{e.message}")
    render json: { error: "Unable to proxy stream" }, status: :bad_gateway unless performed?
  ensure
    close_stream_safely
  end

  private

  def proxy_upstream(uri, redirect_limit = REDIRECT_LIMIT)
    raise "Too many redirects" if redirect_limit.negative?

    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 5,
      read_timeout: 20,
    ) do |http|
      upstream_request = Net::HTTP::Get.new(uri.request_uri)
      upstream_request["Range"] = request.headers["Range"] if request.headers["Range"].present?
      upstream_request["Accept-Encoding"] = "identity"

      http.request(upstream_request) do |upstream_response|
        if upstream_response.is_a?(Net::HTTPRedirection)
          redirect_target = upstream_response["location"]
          raise "Redirect without location" if redirect_target.blank?

          redirected_uri = URI.join(uri.to_s, redirect_target)
          unless allowed_stream_host?(redirected_uri.host)
            render json: { error: "Redirected stream host is not allowed" }, status: :forbidden
            return
          end

          proxy_upstream(redirected_uri, redirect_limit - 1)
          return
        end

        stream_upstream_response(upstream_response, uri)
      end
    end
  end

  def stream_upstream_response(upstream_response, uri)
    self.status = upstream_response.code.to_i

    if upstream_response.is_a?(Net::HTTPSuccess) && hls_playlist?(uri, upstream_response["Content-Type"])
      set_passthrough_headers(upstream_response, strip_content_length: true)
      body = +""
      upstream_response.read_body { |chunk| body << chunk }
      response.stream.write(rewrite_hls_playlist(body, uri))
      return
    end

    set_passthrough_headers(upstream_response)
    upstream_response.read_body { |chunk| response.stream.write(chunk) }
  end

  def set_passthrough_headers(upstream_response, strip_content_length: false)
    PASSTHROUGH_HEADERS.each do |header|
      next if strip_content_length && header == "Content-Length"

      value = upstream_response[header]
      response.headers[header] = value if value.present?
    end
  end

  def hls_playlist?(uri, content_type)
    normalized_content_type = content_type.to_s.split(";").first&.strip
    HLS_CONTENT_TYPES.include?(normalized_content_type) || uri.path.to_s.downcase.end_with?(".m3u8")
  end

  def rewrite_hls_playlist(playlist_body, base_uri)
    playlist_body.each_line.map { |line| rewrite_hls_line(line, base_uri) }.join
  end

  def rewrite_hls_line(line, base_uri)
    stripped_line = line.strip
    return line if stripped_line.blank?

    if stripped_line.start_with?("#")
      return rewrite_hls_uri_attribute(line, base_uri)
    end

    line_ending = line_ending_for(line)
    "#{proxied_url(resolve_hls_uri(stripped_line, base_uri))}#{line_ending}"
  end

  def rewrite_hls_uri_attribute(line, base_uri)
    return line unless line.include?("URI=")

    line.gsub(/URI="([^"]+)"/) do
      original_uri = Regexp.last_match(1)
      rewritten_uri = proxied_url(resolve_hls_uri(original_uri, base_uri))
      "URI=\"#{rewritten_uri}\""
    end
  end

  def resolve_hls_uri(target, base_uri)
    URI.join(base_uri.to_s, CGI.unescapeHTML(target)).to_s
  rescue URI::InvalidURIError
    target
  end

  def proxied_url(url)
    live_proxy_path(url: url)
  end

  def line_ending_for(line)
    return "\r\n" if line.end_with?("\r\n")
    return "\n" if line.end_with?("\n")

    ""
  end

  def parse_upstream_uri(raw_url)
    if raw_url.blank?
      render json: { error: "Missing required parameter: url" }, status: :bad_request
      return
    end

    upstream_uri = URI.parse(raw_url)
    unless upstream_uri.is_a?(URI::HTTP)
      render json: { error: "Only HTTP/HTTPS URLs are supported" }, status: :bad_request
      return
    end

    upstream_uri
  rescue URI::InvalidURIError
    render json: { error: "Invalid stream URL" }, status: :bad_request
    nil
  end

  def allowed_stream_host?(host)
    return false if host.blank?

    normalized_host = host.downcase
    allowed_stream_hosts.any? { |rule| host_matches_rule?(normalized_host, rule) }
  end

  def allowed_stream_hosts
    configured_hosts = normalize_allowed_host_rules(SiteSetting.live_tv_proxy_allowed_stream_hosts)

    configured_hosts.presence || ALLOWED_STREAM_HOSTS
  end

  def normalize_allowed_host_rules(raw_rules)
    rules =
      if raw_rules.is_a?(Array)
        raw_rules
      else
        raw_rules.to_s.split(/[|,\n]/)
      end

    rules.filter_map do |rule|
      normalized_rule = normalize_host_rule(rule)
      normalized_rule.presence
    end
  end

  def normalize_host_rule(rule)
    rule = rule.to_s.strip.downcase
    return "" if rule.blank?

    return rule if rule.start_with?("*.")

    return URI.parse(rule).host.to_s.downcase if rule.include?("://")

    rule.split("/").first
  rescue URI::InvalidURIError
    ""
  end

  def host_matches_rule?(host, rule)
    return false if rule.blank?

    return host == rule unless rule.start_with?("*.")

    suffix = rule.delete_prefix("*.")
    return false if suffix.blank?

    # Wildcard only matches subdomains, e.g. *.provider.com -> cdn.provider.com
    host.end_with?(".#{suffix}")
  end

  def check_live_tv_enabled
    return if SiteSetting.enable_live_tv

    render json: { error: "Live TV is disabled" }, status: :service_unavailable
  end

  def enforce_proxy_concurrency_limit
    return yield if MAX_CONCURRENT_PROXY_REQUESTS <= 0

    acquired_slot = acquire_proxy_slot
    unless acquired_slot
      response.headers["Retry-After"] = "2"
      render json: { error: "Live proxy is busy, try again shortly" }, status: :service_unavailable
      return
    end

    yield
  ensure
    release_proxy_slot if acquired_slot
  end

  def acquire_proxy_slot
    self.class.proxy_requests_mutex.synchronize do
      return false if self.class.proxy_requests_count >= MAX_CONCURRENT_PROXY_REQUESTS

      self.class.proxy_requests_count += 1
      true
    end
  end

  def release_proxy_slot
    self.class.proxy_requests_mutex.synchronize do
      self.class.proxy_requests_count -= 1 if self.class.proxy_requests_count.positive?
    end
  end

  def silence_proxy_logs
    silence_logger(Rails.logger) do
      silence_logger(ActiveRecord::Base.logger) { yield }
    end
  end

  def silence_logger(logger)
    return yield unless logger&.respond_to?(:silence)

    logger.silence(Logger::ERROR) { yield }
  end

  def close_stream_safely
    return unless response.stream.respond_to?(:close)
    return if response.stream.closed?

    response.stream.close
  rescue IOError
    nil
  end
end
