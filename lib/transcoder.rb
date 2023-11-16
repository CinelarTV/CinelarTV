# frozen_string_literal: true

module Transcoder
  QUALITY_PROFILES = {
    "144p" => { video: "libx264", video_profile: "baseline", video_level: "3.0", video_bitrate: "400k", audio: "aac",
                audio_bitrate: "64k", resolution: "256x144" },
    "240p" => { video: "libx264", video_profile: "baseline", video_level: "3.0", video_bitrate: "800k", audio: "aac",
                audio_bitrate: "96k", resolution: "426x240" },
    "360p" => { video: "libx264", video_profile: "main", video_level: "3.1", video_bitrate: "1200k", audio: "aac",
                audio_bitrate: "128k", resolution: "640x360" },
    "480p" => { video: "libx264", video_profile: "main", video_level: "3.1", video_bitrate: "2000k", audio: "aac",
                audio_bitrate: "128k", resolution: "854x480" },
    "720p" => { video: "libx264", video_profile: "high", video_level: "4.1", video_bitrate: "2500k", audio: "aac",
                audio_bitrate: "128k", resolution: "1280x720" },
    "1080p" => { video: "libx264", video_profile: "high", video_level: "4.2", video_bitrate: "4000k", audio: "aac",
                 audio_bitrate: "192k", resolution: "1920x1080" },
    "1440p" => { video: "libx264", video_profile: "high", video_level: "4.2", video_bitrate: "8000k", audio: "aac",
                 audio_bitrate: "192k", resolution: "2560x1440" },
    "2160p" => { video: "libx264", video_profile: "high", video_level: "4.2", video_bitrate: "12000k", audio: "aac",
                 audio_bitrate: "256k", resolution: "3840x2160" },
  }.freeze

  def self.ffmpeg_present?
    system("ffmpeg -version")

    $CHILD_STATUS.success?
  end

  def self.transcode(video_path, output_dir)
    # Verifica si el archivo de video existe
    unless File.exist?(video_path)
      raise "The input file (#{video_path}) does not exist"
    end

    # Crea el directorio de salida si no existe
    FileUtils.mkdir_p(output_dir)

    # Recorre los perfiles de calidad
    QUALITY_PROFILES.each do |quality, options|
      output_file = File.join(output_dir, "#{quality}.m3u8")

      cmd = [
        "ffmpeg",
        "-i", video_path,
        "-c:v", options[:video],
        "-profile:v", options[:video_profile],
        "-level:v", options[:video_level],
        "-b:v", options[:video_bitrate],
        "-c:a", options[:audio],
        "-b:a", options[:audio_bitrate],
        "-vf", "scale=#{options[:resolution]}",
        "-hls_time", "10",
        "-hls_list_size", "0",
        "-f", "hls",
        output_file,
      ]

      # Ejecuta el comando
      system(*cmd)

      unless $?.success?
        raise "An error occurred while transcoding the video to #{quality}"
      end
    end
  end
end
