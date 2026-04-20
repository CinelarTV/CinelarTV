# frozen_string_literal: true

require "version"
require "updater"

module CinelarTV
  @plugins = []
  @plugins_by_name = {}

  class << self
    attr_reader :plugins, :plugins_by_name

    def plugin_by_name(name)
      @plugins_by_name[name]
    end
  end

  def self.git_version
    @git_version ||= try_git("git rev-parse HEAD", CinelarTV::Application::Version::FULL)
  end

  def self.git_branch
    @git_branch ||= try_git("git rev-parse --abbrev-ref HEAD", "unknown")
  end

  def self.is_git_repo?
    @is_git_repo ||= try_git("git rev-parse --is-inside-work-tree", "false") == "true"
  end

  def self.last_commit_date
    @last_commit_date ||= begin
      seconds = try_git('git log -1 --format="%ct"', nil)
      DateTime.strptime(seconds, "%s") if seconds
    end
  end

  def self.full_version
    @full_version ||= try_git('git describe --dirty --match "v[0-9]*" 2> /dev/null', "unknown")
  end

  def self.try_git(git_cmd, default_value)
    result = `#{git_cmd} 2>#{File::NULL}`.strip
    result.empty? ? default_value : result
  rescue StandardError
    default_value
  end

  def self.cache
    @cache ||= ENV["REDIS_URL"].nil? ? ActiveSupport::Cache::MemoryStore.new : Cache.new
  end

  def self.maintenance_enabled
    cache.read("maintenance_enabled") || false
  end

  def self.maintenance_enabled=(value)
    cache.write("maintenance_enabled", value)
  end

  def self.valid_license?
    cached = cache.read("valid_license")

    if cached.nil?
      Rails.logger.info("License validation job not yet run. Running now...")
      LicenseValidationJob.new.perform
      cache.read("valid_license") || false
    else
      cached
    end
  end

  def self.valid_license(value)
    cache.write("valid_license", value)
  end

  class NotFound < StandardError
    attr_reader :status, :original_path, :custom_message

    def initialize(msg = nil, status: 404, original_path: nil, custom_message: nil)
      super(msg)
      @status = status
      @original_path = original_path
      @custom_message = custom_message
    end
  end

  class MaxSimultaneousReproductions < StandardError
    attr_reader :status, :custom_message

    def initialize(msg = nil, status: 429, custom_message: nil)
      super(msg)
      @status = status
      @custom_message = custom_message
    end
  end
end