# frozen_string_literal: true

require "httparty"
require "uri"
require "securerandom"

class MediaIntegrityCheckService
  HLS_CONTENT_TYPES = %w[
    application/vnd.apple.mpegurl
    application/x-mpegURL
    audio/mpegurl
    audio/x-mpegurl
  ].freeze

  def initialize(video_source, options = {})
    @video_source = video_source
    @timeout = options[:timeout] || SiteSetting.media_checker_timeout || 5
    @segment_count = options[:segment_count] || SiteSetting.media_checker_hls_segment_count || 3
    @deep_check = options[:deep_check] != false && (SiteSetting.media_checker_enable_deep_check != false)
  end

  def check
    format = detect_format
    storage = @video_source.storage_location

    case storage
    when "local"
      check_local(format)
    when "cloud"
      check_cloud(format)
    when "external_url"
      check_external(format)
    else
      { success: false, error: "Unknown storage location: #{storage}" }
    end
  end

  private

  def detect_format
    url = @video_source.url
    return @video_source.format if url.blank?

    path = URI.parse(url).path.to_s.downcase
    return "m3u8" if path.end_with?(".m3u8")
    return "mp4" if path.end_with?(".mp4")

    @video_source.format
  rescue URI::InvalidURIError
    @video_source.format
  end

  # ── Local ──────────────────────────────────────────────────────────────

  def check_local(format)
    videoable_id = @video_source.videoable_id
    base_dir = Rails.root.join("public", "content-media", videoable_id.to_s)

    unless Dir.exist?(base_dir)
      return { success: false, error: "Storage directory not found: #{base_dir}" }
    end

    if format == "m3u8"
      check_local_hls(base_dir)
    else
      check_local_mp4(base_dir)
    end
  end

  def check_local_hls(base_dir)
    master_path = base_dir.join("master.m3u8")
    unless File.exist?(master_path)
      return { success: false, error: "master.m3u8 not found in #{base_dir}" }
    end

    master_content = File.read(master_path)
    sub_playlists = parse_m3u8_local(master_content, base_dir)

    if sub_playlists.empty?
      return { success: false, error: "No sub-playlists found in master.m3u8" }
    end

    playlist_path = sub_playlists.first
    unless File.exist?(playlist_path)
      return { success: false, error: "Sub-playlist not found: #{playlist_path}" }
    end

    playlist_content = File.read(playlist_path)
    segments = parse_m3u8_local_ts(playlist_content, playlist_path.dirname)

    if segments.empty?
      return { success: false, error: "No segments found in #{playlist_path.basename}" }
    end

    selected = select_distributed_segments(segments, @segment_count)
    missing = selected.reject { |s| File.exist?(s) }

    if missing.any?
      return { success: false, error: "#{missing.length} segment(s) missing: #{File.basename(missing.first)}" }
    end

    { success: true, details: { format: "m3u8", storage: "local", segments_checked: selected.length } }
  end

  def check_local_mp4(base_dir)
    url_path =
      begin
        URI.parse(@video_source.url).path
      rescue URI::InvalidURIError
        nil
      end
    filename = url_path ? File.basename(url_path) : nil

    if filename
      file_path = base_dir.join(filename)
      return { success: true, details: { format: "mp4", storage: "local" } } if File.exist?(file_path)
    end

    mp4_files = Dir.glob(base_dir.join("*.mp4"))
    if mp4_files.any?
      { success: true, details: { format: "mp4", storage: "local" } }
    else
      { success: false, error: "No MP4 files found in #{base_dir}" }
    end
  end

  # ── Cloud (S3) ─────────────────────────────────────────────────────────

  def check_cloud(format)
    if format == "m3u8" && @deep_check
      check_hls(@video_source.url)
    else
      wrap_head(@video_source.url)
    end
  end

  # ── External URL ───────────────────────────────────────────────────────

  def check_external(format)
    if format == "m3u8" && @deep_check
      check_hls(@video_source.url)
    else
      wrap_head(@video_source.url)
    end
  end

  # ── HLS Check (master or quality playlist) ─────────────────────────────

  # Fetches the URL and determines whether it's a master playlist
  # (references other .m3u8) or a quality playlist (references .ts segments).
  # Verifies a distributed sample of segments.
  def check_hls(url)
    cb_url = cache_busted_url(url)
    response = http_get(cb_url)

    unless response&.success?
      return { success: false, error: "Failed to fetch playlist: HTTP #{response&.code}" }
    end

    body = response.body.to_s

    # Ensure body is properly decoded as UTF-8 text
    body = body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") unless body.encoding == Encoding::UTF_8
    content_type = response.headers["content-type"].to_s.split(";").first&.strip

    Rails.logger.info(
      "[MediaIntegrity] HLS check for VideoSource #{@video_source.id}: " \
      "url=#{url}, ct=#{content_type}, bytes=#{body.length}"
    )

    # Step 1: check if this is a master playlist (contains .m3u8 refs)
    sub_playlist_urls = parse_m3u8_urls(body, url, ext: ".m3u8")

    if sub_playlist_urls.any?
      # Master playlist — fetch first quality sub-playlist
      Rails.logger.info(
        "[MediaIntegrity] Master playlist detected (#{sub_playlist_urls.length} sub-playlists)"
      )
      return verify_segments_from_sub_playlist(sub_playlist_urls.first)
    end

    # Step 2: assume it's a quality playlist — look for .ts segments directly
    segment_urls = parse_m3u8_urls(body, url, ext: ".ts")

    if segment_urls.empty?
      # Debug: log all non-comment, non-blank lines to see what we're parsing
      candidate_lines = body.each_line.map(&:strip).reject { |l| l.blank? || l.start_with?("#") }
      Rails.logger.warn(
        "[MediaIntegrity] No sub-playlists or segments found for VideoSource #{@video_source.id}. " \
        "Candidate lines: #{candidate_lines.first(5).inspect}, " \
        "body bytes: #{body.bytesize}, encoding: #{body.encoding}"
      )
      return { success: false, error: "No sub-playlists or segments found in playlist" }
    end

    verify_segments(segment_urls)
  end

  def verify_segments_from_sub_playlist(sub_url)
    cb_sub_url = cache_busted_url(sub_url)
    sub_response = http_get(cb_sub_url)

    unless sub_response&.success?
      return { success: false, error: "Failed to fetch sub-playlist: HTTP #{sub_response&.code}" }
    end

    segment_urls = parse_m3u8_urls(sub_response.body.to_s, sub_url, ext: ".ts")

    if segment_urls.empty?
      return { success: false, error: "No segments found in sub-playlist" }
    end

    verify_segments(segment_urls)
  end

  def verify_segments(segment_urls)
    selected = select_distributed_segments(segment_urls, @segment_count)
    failures = []

    selected.each do |seg_url|
      cb_seg = cache_busted_url(seg_url)
      res = head_request(cb_seg)
      failures << seg_url unless res&.success?
    end

    if failures.any?
      return { success: false, error: "#{failures.length}/#{selected.length} segments unreachable" }
    end

    {
      success: true,
      details: {
        format: "m3u8",
        storage: @video_source.storage_location,
        total_segments: segment_urls.length,
        segments_checked: selected.length
      }
    }
  end

  # ── M3U8 Parsing ───────────────────────────────────────────────────────

  # Parses an M3U8 body and returns resolved URLs for non-comment lines
  # whose file extension matches `ext:`. Handles query params on lines.
  def parse_m3u8_urls(content, base_url, ext:)
    content.each_line.filter_map do |raw_line|
      line = raw_line.strip
      next if line.blank?
      next if line.start_with?("#")

      candidate = line.split("?").first
      next unless candidate.end_with?(ext)

      resolve_url(line, base_url)
    end
  end

  def parse_m3u8_local(content, base_dir)
    content.each_line.filter_map do |raw_line|
      line = raw_line.strip
      next if line.blank? || line.start_with?("#")
      candidate = line.split("?").first
      next unless candidate.end_with?(".m3u8")
      base_dir.join(candidate).to_s
    end
  end

  def parse_m3u8_local_ts(content, base_dir)
    content.each_line.filter_map do |raw_line|
      line = raw_line.strip
      next if line.blank? || line.start_with?("#")
      candidate = line.split("?").first
      next unless candidate.end_with?(".ts")
      base_dir.join(candidate).to_s
    end
  end

  def resolve_url(target, base_url)
    URI.join(base_url, target).to_s
  rescue URI::InvalidURIError
    nil
  end

  # ── Segment Selection ──────────────────────────────────────────────────

  def select_distributed_segments(items, count)
    return items if items.length <= count

    step = (items.length - 1).to_f / (count - 1)
    Array.new(count) { |i| items[(i * step).round] }
  end

  # ── HTTP Helpers ───────────────────────────────────────────────────────

  def cache_busted_url(url)
    uri = URI.parse(url)
    separator = uri.query ? "&" : "?"
    "#{url}#{separator}_cb=#{SecureRandom.hex(8)}"
  rescue URI::InvalidURIError
    url
  end

  def http_get(url)
    response = HTTParty.get(
      url,
      timeout: @timeout,
      verify: false,
      headers: { "Accept" => "*/*", "Accept-Encoding" => "gzip, deflate" }
    )

    # Decompress gzip/deflate if needed
    if response&.body&.is_a?(String) && response.body.byteslice(0, 2)&.unpack1("H2") == "1f8b"
      require "zlib"
      require "stringio"
      io = StringIO.new(response.body)
      gz = Zlib::GzipReader.new(io)
      response.instance_variable_set(:@body, gz.read)
      gz.close
    end

    response
  rescue StandardError
    nil
  end

  def head_request(url)
    HTTParty.head(
      url,
      timeout: @timeout,
      verify: false
    )
  rescue StandardError
    nil
  end

  def wrap_head(url)
    res = head_request(url)
    if res&.success?
      { success: true, details: { format: @video_source.format, storage: @video_source.storage_location } }
    else
      { success: false, error: "HTTP HEAD failed: #{res&.code || 'timeout'}" }
    end
  end
end
