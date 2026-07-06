# frozen_string_literal: true

require "open3"
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

    puts "  Repository: #{repository}"
    puts "  Tag: #{tag}"
    puts "  GITHUB_TOKEN set: #{ENV['GITHUB_TOKEN'] ? 'yes' : 'no'}"

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

    puts "  Prebuilt assets installed successfully."

    # Mark prebuilt as available so downstream tasks can skip main Vite build
    ENV["PREBUILT_ACTIVE"] = "1"

    # ViteRuby's enhance block invokes vite:build_all and vite:install_dependencies.
    # Clear them so the enhance block becomes a no-op.
    %w[vite:build_all vite:build vite:install_dependencies].each do |task_name|
      if Rake::Task.task_defined?(task_name)
        Rake::Task[task_name].clear
      end
    end
  end

  desc "Compile, package, and publish prebuilt assets to GitHub Releases"
  task publish_prebuilt: :environment do
    repository = PrebuiltAssets.repository
    tag = PrebuiltAssets::Version.release_tag

    puts "  Repository: #{repository}"
    puts "  Tag: #{tag}"
    puts "  GITHUB_TOKEN set: #{ENV['GITHUB_TOKEN'] ? 'yes' : 'no'}"

    client = PrebuiltAssets::GitHubClient.new(repository: repository)

    if client.release_exists?(tag)
      puts "Release #{tag} already exists in #{repository}. Skipping."
      next
    end

    puts "Building Vite assets (production)..."
    out, status = Open3.capture2e(
      { "RAILS_ENV" => "production", "SECRET_KEY_BASE" => ENV.fetch("SECRET_KEY_BASE", "build-only") },
      "bundle", "exec", "vite", "build"
    )
    raise "Vite build failed: #{out}" unless status.success?
    puts out

    vite_dir = PrebuiltAssets.vite_output_dir
    unless Dir.exist?(vite_dir)
      Dir.glob("public/vite*").each { |d| puts "  Found: #{d}" }
      raise "No Vite output found. Looked for: #{vite_dir}."
    end

    puts "Packaging assets from #{vite_dir}..."
    require "tmpdir"
    Dir.mktmpdir("prebuilt-publish-") do |tmp_dir|
      archive = File.join(tmp_dir, PrebuiltAssets::Version.asset_archive_name)
      out, status = Open3.capture2e(
        "tar", "-czf", archive, "-C", File.dirname(vite_dir), File.basename(vite_dir)
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

# After prebuilt extraction, compile third-party plugins
Rake::Task["assets:precompile"].enhance do
  if ENV["PREBUILT_ACTIVE"] == "1"
    puts "  [prebuilt] Compiling third-party plugins..."
    Rake::Task["plugins:compile_third_party"].invoke
  end
end
