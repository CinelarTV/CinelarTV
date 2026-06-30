# frozen_string_literal: true

require "tmpdir"
require "open3"
require "fileutils"

module PrebuiltAssets
  class ArchiveHandler
    def initialize(repo_root: nil, vite_output_dir: nil)
      @repo_root = repo_root || Dir.pwd
      @vite_output_dir = vite_output_dir || File.join(@repo_root, "public", "vite")
    end

    def extract(archive_path)
      Dir.mktmpdir("prebuilt-assets-") do |tmp_dir|
        out, status = Open3.capture2e("tar", "-xzf", archive_path, "-C", tmp_dir)
        raise "Failed to extract archive: #{out}" unless status.success?

        # Find the vite directory in the extracted archive
        vite_src = Dir.glob(File.join(tmp_dir, "vite*")).first
        unless vite_src && Dir.exist?(vite_src)
          raise "Archive missing 'vite' directory. Contents: #{Dir.children(tmp_dir).inspect}"
        end

        FileUtils.rm_rf(@vite_output_dir)
        FileUtils.mkdir_p(File.dirname(@vite_output_dir))
        FileUtils.cp_r(vite_src, @vite_output_dir)
        puts "  Extracted prebuilt assets to #{@vite_output_dir.sub(@repo_root, '.')}"
      end
    end
  end
end
