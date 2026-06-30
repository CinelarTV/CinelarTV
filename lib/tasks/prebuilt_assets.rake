# frozen_string_literal: true

require_relative "../prebuilt_assets"

namespace :assets do
  desc "Download prebuilt assets from GitHub Releases (set CINELAR_DOWNLOAD_PRE_BUILT_ASSETS=1)"
  task download_prebuilt_assets: :environment do
    unless PrebuiltAssets.enabled?
      puts "  Prebuilt assets disabled (set CINELAR_DOWNLOAD_PRE_BUILT_ASSETS=1 to enable)"
      next
    end

    repository = PrebuiltAssets.repository
    tag = PrebuiltAssets::Version.release_tag

    puts "  Checking for prebuilt assets: #{tag} in #{repository}..."

    client = PrebuiltAssets::GitHubClient.new(repository: repository)

    unless client.release_exists?(tag)
      msg = "  Release #{tag} not found in #{repository}"
      if PrebuiltAssets.strict?
        raise "#{msg}. CINELAR_PREBUILT_STRICT=1 is set — aborting instead of falling back."
      else
        puts "#{msg}. Falling back to native compilation."
        next
      end
    end

    puts "  Downloading prebuilt assets from #{tag}..."
    require "tmpdir"
    Dir.mktmpdir("prebuilt-download-") do |tmp_dir|
      archive = File.join(tmp_dir, PrebuiltAssets::Version.asset_archive_name)
      client.download_asset(tag, PrebuiltAssets::Version.asset_archive_name, archive)

      handler = PrebuiltAssets::ArchiveHandler.new
      handler.extract(archive)
    end

    puts "  Prebuilt assets installed successfully. Skipping local compilation."

    Rake::Task["assets:precompile"].prerequisites.clear
  end

  desc "Compile, package, and publish prebuilt assets to GitHub Releases"
  task publish_prebuilt: :environment do
    repository = PrebuiltAssets.repository
    tag = PrebuiltAssets::Version.release_tag

    client = PrebuiltAssets::GitHubClient.new(repository: repository)

    if client.release_exists?(tag)
      puts "Release #{tag} already exists in #{repository}. Skipping."
      next
    end

    puts "Compiling assets locally..."
    Rake::Task["assets:precompile"].invoke

    vite_dir = File.join("public", "vite")
    unless Dir.exist?(vite_dir)
      raise "No Vite output found at public/vite/. Did assets:precompile succeed?"
    end

    puts "Packaging assets..."
    require "tmpdir"
    Dir.mktmpdir("prebuilt-publish-") do |tmp_dir|
      archive = File.join(tmp_dir, PrebuiltAssets::Version.asset_archive_name)
      out, status = Open3.capture2e(
        "tar", "-czf", archive, "-C", "public", "vite"
      )
      raise "Failed to create archive: #{out}" unless status.success?

      archive_size = File.size(archive)
      puts "  Archive created: #{(archive_size / 1024.0 / 1024.0).round(2)} MB"

      puts "Creating release #{tag} in #{repository}..."
      client.create_release(tag, notes: "Prebuilt assets for #{tag}")
      client.upload_asset(tag, archive)
      puts "Release #{tag} published successfully."
    end
  end
end

Rake::Task["assets:precompile"].enhance(["assets:download_prebuilt_assets"])
