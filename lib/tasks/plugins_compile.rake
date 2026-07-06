# frozen_string_literal: true

require "open3"
require "json"
require "yaml"

namespace :plugins do
  desc "Compile third-party plugins not included in prebuilt assets"
  task compile_third_party: :environment do
    plugin_root = Rails.root.join("plugins")
    output_base = Rails.root.join("public", "plugins")
    manifest_path = output_base.join("manifest.json")
    vite_config = Rails.root.join("vite.config.plugins.ts")

    unless File.exist?(vite_config)
      puts "  [plugins:compile_third_party] vite.config.plugins.ts not found, skipping"
      next
    end

    # Load first-party plugin names
    first_party_file = Rails.root.join("config", "first_party_plugins.yml")
    first_party = if File.exist?(first_party_file)
      YAML.safe_load_file(first_party_file)&.fetch("first_party", []) || []
    else
      []
    end

    # Discover all plugins with plugin.json
    plugin_jsons = Dir.glob(plugin_root.join("*/plugin.json"))
    third_party = plugin_jsons.filter_map do |pj|
      data = JSON.parse(File.read(pj))
      plugin_dir = File.dirname(pj)
      next if first_party.include?(data["name"])
      { dir: plugin_dir, name: data["name"], json: data }
    end

    if third_party.empty?
      puts "  [plugins:compile_third_party] No third-party plugins found"
      FileUtils.mkdir_p(output_base)
      File.write(manifest_path, JSON.pretty_generate([]))
      next
    end

    puts "  [plugins:compile_third_party] Found #{third_party.size} third-party plugin(s):"
    third_party.each { |p| puts "    - #{p[:name]}" }

    compiled = []

    third_party.each do |plugin|
      puts "  [plugins:compile_third_party] Compiling #{plugin[:name]}..."

      out, status = Open3.capture2e(
        {
          "RAILS_ENV" => Rails.env,
          "SECRET_KEY_BASE" => ENV.fetch("SECRET_KEY_BASE", "build-only"),
          "PLUGIN_DIR" => plugin[:dir],
          "NODE_OPTIONS" => "--max-old-space-size=2048",
        },
        "npx", "vite", "build", "--mode", "production", "--config", vite_config.to_s
      )

      unless status.success?
        warn "  [plugins:compile_third_party] FAILED to compile #{plugin[:name]}:"
        warn out
        next
      end

      # Scan output directory for actual hashed filenames
      plugin_out_dir = output_base.join(plugin[:name])
      entry = {
        name: plugin[:name],
        version: plugin[:json]["version"],
        js: [],
        css: [],
      }

      if Dir.exist?(plugin_out_dir)
        Dir.children(plugin_out_dir).sort.each do |file|
          next if file.start_with?(".")
          next if File.directory?(plugin_out_dir.join(file))

          if file.end_with?(".js")
            entry[:js] << file
          elsif file.end_with?(".css")
            entry[:css] << file
          end
        end
      end

      compiled << entry
      puts "  [plugins:compile_third_party] ✓ #{plugin[:name]} compiled (#{entry[:js].size} js, #{entry[:css].size} css)"
    end

    # Write manifest
    FileUtils.mkdir_p(output_base)
    File.write(manifest_path, JSON.pretty_generate(compiled))
    puts "  [plugins:compile_third_party] Manifest written to #{manifest_path}"
    puts "  [plugins:compile_third_party] Done: #{compiled.size} plugin(s) compiled"
  end

  desc "List all installed third-party plugins"
  task list_third_party: :environment do
    plugin_root = Rails.root.join("plugins")
    first_party_file = Rails.root.join("config", "first_party_plugins.yml")
    first_party = if File.exist?(first_party_file)
      YAML.safe_load_file(first_party_file)&.fetch("first_party", []) || []
    else
      []
    end

    plugin_jsons = Dir.glob(plugin_root.join("*/plugin.json"))
    third_party = plugin_jsons.filter_map do |pj|
      data = JSON.parse(File.read(pj))
      next if first_party.include?(data["name"])
      "#{data['name']}@#{data['version']}"
    end

    if third_party.empty?
      puts "No third-party plugins installed."
    else
      puts "Third-party plugins (#{third_party.size}):"
      third_party.each { |p| puts "  - #{p}" }
    end
  end
end
