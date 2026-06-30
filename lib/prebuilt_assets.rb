# frozen_string_literal: true

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
end
