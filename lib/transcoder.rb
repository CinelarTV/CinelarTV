# frozen_string_literal: true

require 'fileutils'

module Transcoder
  QUALITY_PROFILES = {
    "144" => { video_bitrate: "400k", audio_bitrate: "64k", resolution: "256x144" },
    "240" => { video_bitrate: "800k", audio_bitrate: "96k", resolution: "426x240" },
    "360" => { video_bitrate: "1200k", audio_bitrate: "128k", resolution: "640x360" },
    "480" => { video_bitrate: "2000k", audio_bitrate: "128k", resolution: "854x480" },
    "720" => { video_bitrate: "2500k", audio_bitrate: "128k", resolution: "1280x720" },
    "1080" => { video_bitrate: "4000k", audio_bitrate: "192k", resolution: "1920x1080" },
    "1440" => { video_bitrate: "8000k", audio_bitrate: "192k", resolution: "2560x1440" },
    "2160" => { video_bitrate: "12000k", audio_bitrate: "256k", resolution: "3840x2160" },
  }.freeze

  def self.calculate_quality_profile(height)
    height = height.to_i

    # Calculate width based on 16:9 aspect ratio
    width = (height * 16.0 / 9.0).to_i

    # Calculate bitrate based on height (rough formula: height * 4-5 kbps depending on resolution)
    base_bitrate_per_pixel = if height <= 480
                               4.0
                             elsif height <= 720
                               3.5
                             elsif height <= 1080
                               3.0
                             elsif height <= 1440
                               2.5
                             else
                               2.0
                             end

    video_bitrate = ((width * height * base_bitrate_per_pixel / 1000).to_i).to_s + "k"

    # Calculate audio bitrate based on video quality
    audio_bitrate = if height <= 480
                     "96k"
                   elsif height <= 720
                     "128k"
                   elsif height <= 1080
                     "192k"
                   else
                     "256k"
                   end

    {
      video_bitrate: video_bitrate,
      audio_bitrate: audio_bitrate,
      resolution: "#{width}x#{height}"
    }
  end

  def self.ffmpeg_present?
    system("ffmpeg -version")
    $CHILD_STATUS.success?
  end

  def self.transcode_to_quality(video_path, quality, output_dir, options = {})
    unless ffmpeg_present?
      return { success: false, error: "FFmpeg is not installed" }
    end

    unless File.exist?(video_path)
      return { success: false, error: "Input file does not exist: #{video_path}" }
    end

    FileUtils.mkdir_p(output_dir)

    # Get settings
    segment_duration = options[:segment_duration] || SiteSetting.transcoding_hls_segment_duration
    video_codec = options[:video_codec] || SiteSetting.transcoding_video_codec
    ffmpeg_threads = options[:ffmpeg_threads] || SiteSetting.transcoding_ffmpeg_threads
    custom_args = options[:custom_args] || SiteSetting.transcoding_ffmpeg_args
    progress_callback = options[:progress_callback]

    # Get quality profile (use predefined or calculate dynamically)
    quality_profile = QUALITY_PROFILES[quality.to_s] || calculate_quality_profile(quality)

    Rails.logger.info "Using quality profile for #{quality}: #{quality_profile}"

    output_file = File.join(output_dir, "#{quality}p.m3u8")

    # Build FFmpeg command
    cmd = [
      "ffmpeg",
      "-i", video_path,
      "-c:v", video_codec,
      "-profile:v", "high",
      "-level:v", "4.0",
      "-b:v", quality_profile[:video_bitrate],
      "-maxrate:v", quality_profile[:video_bitrate],
      "-bufsize:v", (quality_profile[:video_bitrate].to_i * 2).to_s + "k",
      "-c:a", "aac",
      "-b:a", quality_profile[:audio_bitrate],
      "-vf", "scale=#{quality_profile[:resolution]}",
      "-hls_time", segment_duration.to_s,
      "-hls_list_size", "0",
      "-hls_segment_filename", File.join(output_dir, "#{quality}p_%03d.ts"),
      "-threads", ffmpeg_threads.to_s,
      "-progress", "pipe:1",
    ]

    # Add custom FFmpeg args if provided
    if custom_args.present?
      cmd.concat(custom_args.split)
    end

    cmd << "-f"
    cmd << "hls"
    cmd << output_file

    # Execute command with progress tracking
    Rails.logger.info "Running FFmpeg: #{cmd.join(' ')}"

    Open3.popen3(*cmd) do |stdin, stdout, stderr, thread|
      stdin.close

      # Track progress from FFmpeg stderr (where progress data is sent)
      duration = nil
      line_count = 0
      while line = stderr.gets
        line_count += 1
        Rails.logger.debug "FFmpeg stderr line #{line_count}: #{line.strip}" if line_count <= 5 || line_count % 100 == 0

        if line =~ /Duration: (\d+):(\d+):(\d+\.\d+)/
          duration = $1.to_i * 3600 + $2.to_i * 60 + $3.to_f
          Rails.logger.info "Detected video duration from stderr: #{duration}s"
        elsif line =~ /time=(\d+):(\d+):(\d+\.\d+)/ && duration
          current_time = $1.to_i * 3600 + $2.to_i * 60 + $3.to_f
          progress = ((current_time / duration) * 100).round(2)

          Rails.logger.debug "Progress: #{progress}% (#{current_time}s / #{duration}s)"

          # Call progress callback if provided
          if progress_callback && progress <= 100
            progress_callback.call(quality, progress)
          end
        end
      end

      Rails.logger.info "Read #{line_count} lines from FFmpeg stderr"

      stdout_str = stdout.read
      status = thread.value

      unless status.success?
        error_msg = stdout_str.empty? ? "Unknown FFmpeg error" : stdout_str
        Rails.logger.error "FFmpeg error for quality #{quality}: #{error_msg}"
        return { success: false, error: error_msg }
      end
    end

    { success: true, url: "/uploads/transcoded/#{File.basename(output_file)}" }
  rescue StandardError => e
    Rails.logger.error "Transcoding error for quality #{quality}: #{e.message}"
    { success: false, error: e.message }
  end

  def self.get_video_info(video_path)
    return nil unless File.exist?(video_path)

    cmd = ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", video_path]
    stdout, _, status = Open3.capture3(*cmd)

    return nil unless status.success?

    JSON.parse(stdout)
  rescue StandardError => e
    Rails.logger.error "Error getting video info: #{e.message}"
    nil
  end
end
