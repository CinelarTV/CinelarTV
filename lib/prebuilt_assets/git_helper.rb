# frozen_string_literal: true

require "open3"

module PrebuiltAssets
  module GitHelper
    module_function

    def current_sha
      out, status = Open3.capture2e("git", "rev-parse", "HEAD")
      raise "Failed to get git commit SHA: #{out}" unless status.success?
      out.strip
    end

    def short_sha
      current_sha[0, 8]
    end
  end
end
