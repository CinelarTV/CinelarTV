namespace :assets do
  desc "Ensures that dependencies required to compile assets are installed"
  task install_dependencies: :environment do
    next unless File.exist?("package.json")

    # Detect Node.js
    node_version = `node --version 2>/dev/null`.strip
    unless $?.success? && node_version.match?(/^v\d+/)
      raise "Node.js is not installed or not in PATH. Install it from https://nodejs.org (detected: '#{node_version}')"
    end
    Rails.logger.info "Node.js #{node_version} detected"

    # Detect pnpm (v6+)
    pnpm_version = `pnpm --version 2>/dev/null`.strip
    unless $?.success? && pnpm_version.match?(/^\d+\.\d+/)
      raise "pnpm is not installed or not in PATH. Install it with: npm install -g pnpm (detected: '#{pnpm_version}')"
    end

    major = pnpm_version.split(".").first.to_i
    unless major >= 6
      raise "pnpm v6+ is required, but found v#{pnpm_version}. Upgrade with: npm install -g pnpm"
    end
    Rails.logger.info "pnpm v#{pnpm_version} detected"

    # Adjust build environment based on available Node.js heap memory
    build_env = {}

    heap_mb = `node -e "console.log(v8.getHeapStatistics().heap_size_limit/1024/1024)" 2>/dev/null`.to_f

    if heap_mb > 0 && heap_mb < 2048
      Rails.logger.warn "Node.js heap_size_limit is #{heap_mb.round}MB (<2048MB). " \
                        "Setting --max-old-space-size=2048, CHEAP_SOURCE_MAPS=1 and JOBS=1"
      build_env["NODE_OPTIONS"]      = "--max_old_space_size=2048"
    end

    # Install dependencies
    unless system(build_env, "pnpm install --frozen-lockfile")
      raise "pnpm install --frozen-lockfile failed (exit code #{$?.exitstatus}). " \
            "Run 'pnpm install' locally and commit the updated lockfile."
    end
  end
end

Rake::Task["assets:precompile"].enhance(["assets:install_dependencies"])