# frozen_string_literal: true

module PrebuiltAssets
  module Version
    module_function

    def release_tag(commit_sha = nil)
      sha = commit_sha || GitHelper.current_sha
      "#{PrebuiltAssets.release_prefix}-#{sha[0, 8]}"
    end

    def asset_archive_name
      "prebuilt-assets.tar.gz"
    end
  end
end
