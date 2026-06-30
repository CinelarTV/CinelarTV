# frozen_string_literal: true

require "json"
require_relative "prebuilt_assets/git_helper"
require_relative "prebuilt_assets/github_client"
require_relative "prebuilt_assets/archive_handler"
require_relative "prebuilt_assets/version"

module PrebuiltAssets
  module_function

  def enabled?
    ENV["CINELAR_DOWNLOAD_PRE_BUILT_ASSETS"] == "1"
  end

  def strict?
    ENV["CINELAR_PREBUILT_STRICT"] == "1"
  end

  def repository
    ENV.fetch("PREBUILT_ASSETS_REPOSITORY", "CinelarTV/cinelar-assets")
  end

  def release_prefix
    ENV.fetch("PREBUILT_ASSETS_RELEASE_PREFIX", "prebuilt")
  end

  def vite_output_dir
    config_file = Rails.root.join("config", "vite.json")
    if File.exist?(config_file)
      config = JSON.parse(File.read(config_file))
      env_config = config[Rails.env] || config["all"] || {}
      output_dir = env_config["publicOutputDir"]
      return Rails.root.join("public", output_dir) if output_dir.present?
    end
    Rails.root.join("public", "vite")
  end
end
