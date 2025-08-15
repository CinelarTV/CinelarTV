# frozen_string_literal: true

require "version"
require "updater"

module CinelarTV
  def self.git_version
    @git_version ||= begin
      git_cmd = "git rev-parse HEAD"
      try_git(git_cmd, CinelarTV::Application::Version::FULL)
    end
  end

  def self.git_branch
    @git_branch ||= begin
      git_cmd = "git rev-parse --abbrev-ref HEAD"
      try_git(git_cmd, "unknown")
    end
  end

  def self.last_commit_date
    @last_commit_date ||= begin
      git_cmd = 'git log -1 --format="%ct"'
      seconds = try_git(git_cmd, nil)
      seconds.nil? ? nil : DateTime.strptime(seconds, "%s")
    end
  end

  def self.try_git(git_cmd, default_value)
    version_value = false

    begin
      version_value = `#{git_cmd}`.strip
    rescue StandardError
      version_value = default_value
    end

    version_value = default_value if version_value.empty?
    version_value
  end

  def self.full_version
    @full_version ||= begin
      git_cmd = 'git describe --dirty --match "v[0-9]*" 2> /dev/null'
      try_git(git_cmd, "unknown")
    end
  end

  @@maintenance_enabled = false

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
    if cache.read("valid_license").nil?
      Rails.logger.info("License validation job not yet run. Running now...")
      LicenseValidationJob.new.perform
      # Return the value from the cache, if not present, return false
      cache.read("valid_license") || false
    else
      cache.read("valid_license")
    end
  end

  def self.valid_license(value)
    cache.write("valid_license", value)
  end

  class NotFound < StandardError
    attr_reader :status, :original_path, :custom_message

    def initialize(
      msg = nil,
      status: 404,
      original_path: nil,
      custom_message: nil
    )
      super(msg)

      @status = status
      @original_path = original_path
      @custom_message = custom_message
    end
  end

  class MaxSimultaneousReproductions < StandardError
    ## Este error se lanza cuando se supera el número máximo de reproducciones simultáneas permitidas
    ## para un usuario.
    attr_reader :status, :custom_message

    def initialize(msg = nil, status: 429, custom_message: nil)
      super(msg)

      @status = status
      @custom_message = custom_message
    end
  end
end
