# frozen_string_literal: true

require "open3"
require "fileutils"

module PrebuiltAssets
  class GitHubClient
    attr_reader :repository

    def initialize(repository:)
      @repository = repository
      verify_gh_installed!
    end

    def release_exists?(tag)
      _out, status = run_gh("release", "view", tag, "--json", "name")
      status.success?
    end

    def create_release(tag, notes: nil)
      args = ["release", "create", tag, "--title", tag]
      args += ["--notes", notes || tag]
      out, status = run_gh(*args)
      raise "Failed to create release #{tag}: #{out}" unless status.success?
      true
    end

    def upload_asset(tag, file_path)
      out, status = run_gh("release", "upload", tag, file_path, "--clobber")
      raise "Failed to upload asset to release #{tag}: #{out}" unless status.success?
      true
    end

    def download_asset(tag, asset_name, dest_path)
      dir = File.dirname(dest_path)
      out, status = run_gh(
        "release", "download", tag,
        "--pattern", asset_name,
        "--dir", dir,
        "--skip-existing"
      )
      raise "Failed to download asset from release #{tag}: #{out}" unless status.success?

      downloaded = File.join(dir, asset_name)
      FileUtils.mv(downloaded, dest_path) if File.exist?(downloaded) && downloaded != dest_path
      true
    end

    private

    def verify_gh_installed!
      _out, status = Open3.capture2e("gh", "--version")
      return if status.success?

      raise "GitHub CLI (gh) is not installed. Install it from https://cli.github.com/ " \
            "or use: apt install gh / brew install gh / scoop install gh"
    end

    def run_gh(*args)
      env = ENV["GITHUB_TOKEN"] ? { "GH_TOKEN" => ENV["GITHUB_TOKEN"] } : {}
      Open3.capture2e(env, "gh", "--repo", repository, *args)
    end
  end
end
