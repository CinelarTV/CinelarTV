# frozen_string_literal: true

class VideoTranscodingJob
  include Sidekiq::Job
  sidekiq_options queue: :video_transcoding, retry: 0

  def perform(video_source_id, retry_count = 0)
    Rails.logger.info "VideoTranscodingJob started for video_source_id: #{video_source_id}"

    # Check if transcoding is enabled
    unless SiteSetting.enable_transcoding
      Rails.logger.warn "Transcoding is disabled in SiteSettings"
      return
    end

    # Check if video source still exists
    video_source = VideoSource.find_by(id: video_source_id)
    unless video_source
      Rails.logger.warn "VideoSource #{video_source_id} not found"
      return
    end

    Rails.logger.info "VideoSource found: id=#{video_source.id}, status=#{video_source.status}, temp_path=#{video_source.temp_path}"

    # Check if still pending and has temp_path
    unless video_source.status == 'pending' && video_source.temp_path.present?
      Rails.logger.warn "VideoSource not ready for transcoding: status=#{video_source.status}, temp_path_present=#{video_source.temp_path.present?}"
      return
    end

    video_source.update(status: 'processing')

    # Notify start of transcoding
    MessageBus.publish("/transcoding/#{video_source_id}", {
      status: 'started',
      video_source_id: video_source_id,
      timestamp: Time.current.to_i
    })

    # Get transcoding settings
    requested_qualities = SiteSetting.transcoding_qualities.split('|').map(&:to_i).sort.map(&:to_s)
    max_retries = SiteSetting.transcoding_max_retries
    retry_delay = SiteSetting.transcoding_retry_delay
    fail_action = SiteSetting.transcoding_fail_action
    segment_duration = SiteSetting.transcoding_hls_segment_duration
    video_codec = SiteSetting.transcoding_video_codec
    ffmpeg_threads = SiteSetting.transcoding_ffmpeg_threads
    custom_ffmpeg_args = SiteSetting.transcoding_ffmpeg_args

    Rails.logger.info "Starting transcoding for VideoSource #{video_source_id}"

    # Get original video resolution
    video_info = Transcoder.get_video_info(video_source.temp_path)
    original_height = 0
    original_width = 0

    if video_info && video_info['streams']
      video_stream = video_info['streams'].find { |s| s['codec_type'] == 'video' }
      if video_stream
        original_height = video_stream['height'] || 0
        original_width = video_stream['width'] || 0
        Rails.logger.info "Original video resolution: #{original_width}x#{original_height}"
      end
    end

    # Filter qualities to only include those equal or lower than original resolution
    qualities = requested_qualities.select do |quality|
      quality_height = quality.to_i
      quality_height <= original_height || original_height == 0
    end

    if qualities.empty?
      Rails.logger.warn "No valid qualities to transcode (original: #{original_height}p, requested: #{requested_qualities.join(', ')})"
      # Use the lowest requested quality (scale down if necessary)
      qualities = [requested_qualities.first]
      Rails.logger.info "Using lowest quality #{qualities.first}p (will scale down from #{original_height}p)"
    end

    Rails.logger.info "Qualities to transcode: #{qualities.join(', ')}, Codec: #{video_codec}, Threads: #{ffmpeg_threads}"

    begin
      # Process each quality
      results = {}
      total_qualities = qualities.length
      qualities.each_with_index do |quality, index|
        # Check if video source still exists before each quality
        video_source = VideoSource.find_by(id: video_source_id)
        unless video_source
          Rails.logger.info "VideoSource #{video_source_id} was deleted, stopping transcoding"
          return
        end

        # Notify progress
        progress = ((index.to_f / total_qualities) * 100).round(2)
        MessageBus.publish("/transcoding/#{video_source_id}", {
          status: 'processing',
          video_source_id: video_source_id,
          quality: quality,
          progress: progress,
          timestamp: Time.current.to_i
        })

        result = transcode_quality(
          video_source,
          quality,
          segment_duration,
          video_codec,
          ffmpeg_threads,
          custom_ffmpeg_args
        )
        results[quality] = result

        # If fail_action is 'fail' and a quality fails, stop processing
        if result[:success] == false && fail_action == 'fail'
          Rails.logger.error "Transcoding failed for quality #{quality}, stopping due to fail_action: fail"
          raise StandardError, "Transcoding failed for quality #{quality}: #{result[:error]}"
        end
      end

      # If we got here, either all succeeded or we're skipping failures
      successful_qualities = results.select { |_, r| r[:success] }.keys
      failed_qualities = results.select { |_, r| !r[:success] }.keys

      if successful_qualities.empty?
        raise StandardError, "All qualities failed to transcode"
      end

      # Generate master.m3u8 playlist BEFORE moving files to storage
      output_dir = Rails.root.join('tmp', 'transcoding', video_source.id.to_s)
      master_playlist_path = File.join(output_dir, 'master.m3u8')

      # Get base URL first (we need it for the master playlist)
      storage_provider = SiteSetting.storage_provider
      base_path = "/content-media/#{video_source.videoable_id}"
      base_url = if storage_provider == 'local'
                   "#{SiteSetting.base_url}#{base_path}"
                 elsif storage_provider == 's3'
                   cdn_url = SiteSetting.cdn_enabled ? SiteSetting.cdn_url : nil
                   if cdn_url
                     "#{cdn_url}#{base_path}"
                   else
                     bucket = SiteSetting.s3_bucket
                     region = SiteSetting.s3_region || 'us-east-1'
                     "https://#{bucket}.s3.#{region}.amazonaws.com#{base_path}"
                   end
                 end

      # Generate master playlist
      generate_master_playlist(master_playlist_path, successful_qualities, base_url)

      # Copy master playlist to storage BEFORE moving other files
      if storage_provider == 'local'
        target_dir = Rails.root.join('public', 'content-media', video_source.videoable_id.to_s)
        FileUtils.mkdir_p(target_dir)
        FileUtils.cp(master_playlist_path, target_dir)
        master_url = "#{base_url}/master.m3u8"
      elsif storage_provider == 's3'
        # For S3, upload master playlist
        s3_client = Aws::S3::Client.new(
          access_key_id: SiteSetting.s3_access_key_id,
          secret_access_key: SiteSetting.s3_secret_access_key,
          region: SiteSetting.s3_region || 'us-east-1',
          endpoint: SiteSetting.s3_endpoint
        )
        bucket = SiteSetting.s3_bucket
        s3_key = "content-media/#{video_source.videoable_id}/master.m3u8"
        s3_client.put_object(
          bucket: bucket,
          key: s3_key,
          body: File.open(master_playlist_path),
          acl: 'public-read'
        )
        master_url = "#{base_url}/master.m3u8"
      end

      # Move transcoded files to storage
      storage_result = TranscodedFileStorageService.store_transcoded_files(output_dir, video_source)

      unless storage_result[:success]
        raise StandardError, "Failed to store transcoded files: #{storage_result[:error]}"
      end

      transcoded_url = master_url

      Rails.logger.info "Updating VideoSource #{video_source.id}: url=#{transcoded_url}, status=completed, quality=adaptative"

      # Save temp_path before update so we can delete the file after
      original_temp_path = video_source.temp_path

      video_source.update!(
        url: transcoded_url,
        status: 'completed',
        temp_path: nil,
        quality: 'adaptative',
        format: 'm3u8',
        storage_location: storage_provider == 'local' ? 'local' : 'cloud'
      )

      Rails.logger.info "VideoSource updated successfully: id=#{video_source.id}, url=#{video_source.url}, status=#{video_source.status}, quality=#{video_source.quality}"

      # Delete temporary source file
      if original_temp_path && File.exist?(original_temp_path)
        FileUtils.rm_f(original_temp_path)
        Rails.logger.info "Deleted temporary source file: #{original_temp_path}"
      end

      Rails.logger.info "Transcoding completed for VideoSource #{video_source_id}"
      Rails.logger.info "Successful qualities: #{successful_qualities.join(', ')}"
      Rails.logger.warn "Failed qualities: #{failed_qualities.join(', ')}" if failed_qualities.any?

      # Notify completion
      MessageBus.publish("/transcoding/#{video_source_id}", {
        status: 'completed',
        video_source_id: video_source_id,
        url: transcoded_url,
        successful_qualities: successful_qualities,
        failed_qualities: failed_qualities,
        timestamp: Time.current.to_i
      })

    rescue StandardError => e
      # Handle retry logic
      if retry_count < max_retries
        Rails.logger.warn "Transcoding failed for VideoSource #{video_source_id}, retrying in #{retry_delay}s (attempt #{retry_count + 1}/#{max_retries})"
        Rails.logger.error "Error: #{e.message}"

        # Notify retry
        MessageBus.publish("/transcoding/#{video_source_id}", {
          status: 'retrying',
          video_source_id: video_source_id,
          retry_count: retry_count + 1,
          max_retries: max_retries,
          error: e.message,
          timestamp: Time.current.to_i
        })

        # Schedule retry
        VideoTranscodingJob.perform_in(retry_delay.seconds, video_source_id, retry_count + 1)
        video_source.update(status: 'pending') # Reset to pending for retry
      else
        # Max retries reached, mark as failed
        video_source.update(status: 'failed')
        Rails.logger.error "Transcoding failed for VideoSource #{video_source_id} after #{max_retries} retries: #{e.message}"

        # Notify failure
        MessageBus.publish("/transcoding/#{video_source_id}", {
          status: 'failed',
          video_source_id: video_source_id,
          error: e.message,
          timestamp: Time.current.to_i
        })
      end
    end
  end

  private

  def generate_master_playlist(output_path, qualities, base_url)
    File.open(output_path, 'w') do |file|
      file.puts "#EXTM3U"
      file.puts "#EXT-X-VERSION:3"

      qualities.each do |quality|
        file.puts "#EXT-X-STREAM-INF:BANDWIDTH=#{get_bandwidth_for_quality(quality)},RESOLUTION=#{get_resolution_for_quality(quality)}"
        file.puts "#{base_url}/#{quality}p.m3u8"
      end
    end

    Rails.logger.info "Generated master playlist at #{output_path} with qualities: #{qualities.join(', ')}"
  end

  def get_bandwidth_for_quality(quality)
    bandwidths = {
      '144' => '300000',
      '240' => '800000',
      '360' => '1200000',
      '480' => '2000000',
      '720' => '3500000',
      '1080' => '6000000',
      '1440' => '10000000',
      '2160' => '20000000'
    }
    bandwidths[quality.to_s] || '800000'
  end

  def get_resolution_for_quality(quality)
    resolutions = {
      '144' => '256x144',
      '240' => '426x240',
      '360' => '640x360',
      '480' => '854x480',
      '720' => '1280x720',
      '1080' => '1920x1080',
      '1440' => '2560x1440',
      '2160' => '3840x2160'
    }
    resolutions[quality.to_s] || '426x240'
  end

  def transcode_quality(video_source, quality, segment_duration, video_codec, ffmpeg_threads, custom_ffmpeg_args)
    Rails.logger.info "Transcoding quality #{quality} for VideoSource #{video_source.id}"

    # Create output directory
    output_dir = Rails.root.join('tmp', 'transcoding', video_source.id.to_s)

    # Progress callback for MessageBus
    progress_callback = lambda do |q, progress|
      MessageBus.publish("/transcoding/#{video_source.id}", {
        status: 'processing_quality',
        video_source_id: video_source.id,
        quality: q,
        quality_progress: progress,
        timestamp: Time.current.to_i
      })
    end

    # Transcode using real FFmpeg
    result = Transcoder.transcode_to_quality(
      video_source.temp_path,
      quality,
      output_dir,
      segment_duration: segment_duration,
      video_codec: video_codec,
      ffmpeg_threads: ffmpeg_threads,
      custom_args: custom_ffmpeg_args,
      progress_callback: progress_callback
    )

    result
  end
end
