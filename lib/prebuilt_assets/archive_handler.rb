# frozen_string_literal: true

require "tmpdir"
require "open3"
require "fileutils"

module PrebuiltAssets
  class ArchiveHandler
    VITE_DIR = "vite"

    def initialize(repo_root: nil)
      @repo_root = repo_root || Dir.pwd
    end

    def extract(archive_path)
      Dir.mktmpdir("prebuilt-assets-") do |tmp_dir|
        out, status = Open3.capture2e("tar", "-xzf", archive_path, "-C", tmp_dir)
        raise "Failed to extract archive: #{out}" unless status.success?

        vite_src = File.join(tmp_dir, VITE_DIR)
        unless Dir.exist?(vite_src)
          raise "Archive missing '#{VITE_DIR}' directory. Contents: #{Dir.children(tmp_dir).inspect}"
        end

        dest = File.join(@repo_root, "public", VITE_DIR)
        FileUtils.rm_rf(dest)
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp_r(vite_src, dest)
        puts "  Extracted prebuilt assets to public/#{VITE_DIR}/"
      end
    end
  end
end
