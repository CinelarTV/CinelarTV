# frozen_string_literal: true

require "json"
require_relative "../plugin/public_packages"

namespace :plugins do
  desc "Generate the browser import map for CinelarTV public plugin packages"
  task generate_importmap: :environment do
    manifest_path = Rails.root.join("public", "vite", ".vite", "manifest.json")
    output_path = Rails.root.join("public", "vite", "cinelartv-plugin-importmap.json")

    unless File.exist?(manifest_path)
      warn "[plugins:generate_importmap] Vite manifest not found: #{manifest_path}"
      next
    end

    vite_manifest = JSON.parse(File.read(manifest_path))
    imports = Plugin::PublicPackages::PACKAGES.each_with_object({}) do |(package_name, entry), map|
      asset = vite_manifest[entry]
      raise "[plugins:generate_importmap] Missing public entry #{entry}" unless asset&.fetch("file", nil)

      map[package_name] = "/vite/#{asset.fetch("file")}" 
    end

    FileUtils.mkdir_p(output_path.dirname)
    File.write(output_path, JSON.pretty_generate({ "imports" => imports }) + "\n")
    puts "[plugins:generate_importmap] Wrote #{output_path}"
  end
end

# ViteRuby enhances assets:precompile with its build task. An enhance block runs
# after those prerequisites, so the generated map always reads the real hashed
# Vite manifest instead of relying on build ordering.
Rake::Task["assets:precompile"].enhance do
  Rake::Task["plugins:generate_importmap"].invoke
end
