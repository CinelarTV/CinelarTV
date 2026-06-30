# frozen_string_literal: true

require "open3"
require "json"
require "fileutils"

module PrebuiltAssets
  class GitHubClient
    attr_reader :repository

    def initialize(repository:)
      @repository = repository
      @api_base = "https://api.github.com/repos/#{repository}"
    end

    def release_exists?(tag)
      out, status = curl_get("#{@api_base}/releases/tags/#{tag}")
      status.success?
    end

    def create_release(tag, notes: nil)
      require_gh!
      args = ["release", "create", tag, "--title", tag]
      args += ["--notes", notes || tag]
      out, status = run_gh(*args)
      raise "Failed to create release #{tag}: #{out}" unless status.success?
      true
    end

    def upload_asset(tag, file_path)
      require_gh!
      out, status = run_gh("release", "upload", tag, file_path, "--clobber")
      raise "Failed to upload asset to release #{tag}: #{out}" unless status.success?
      true
    end

    def download_asset(tag, asset_name, dest_path)
      # Find the asset download URL via API (no auth needed for public repos)
      out, status = curl_get("#{@api_base}/releases/tags/#{tag}")
      raise "Release #{tag} not found: #{out}" unless status.success?

      release = JSON.parse(out)
      asset = release["assets"]&.find { |a| a["name"] == asset_name }
      raise "Asset #{asset_name} not found in release #{tag}" unless asset

      download_url = asset["browser_download_url"]
      puts "  Downloading from #{download_url}"

      FileUtils.mkdir_p(File.dirname(dest_path))
      out, status = curl_download(download_url, dest_path)
      raise "Failed to download #{asset_name}: #{out}" unless status.success?

      true
    end

    private

    def require_gh!
      _out, status = Open3.capture2e("gh", "--version")
      return if status.success?

      raise "GitHub CLI (gh) is not installed and is required for this operation. " \
            "Install from https://cli.github.com/ or use: apt install gh"
    end

    def run_gh(*args)
      env = ENV["GITHUB_TOKEN"] ? { "GH_TOKEN" => ENV["GITHUB_TOKEN"] } : {}
      Open3.capture2e(env, "gh", "--repo", repository, *args)
    end

    def curl_get(url)
      Open3.capture2e("curl", "-fsSL", url)
    end

    def curl_download(url, dest)
      Open3.capture2e("curl", "-fsSL", "-o", dest, url)
    end
  end
end
