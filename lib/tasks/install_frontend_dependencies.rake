namespace :assets do
  desc "Ensures that dependencies required to compile assets are installed"
  task install_dependencies: :environment do
    next unless File.exist?("package.json")

    # Detect Node.js
    node_version = `node --version 2>&1`.strip
    unless $?.success? && node_version.match?(/^v\d+/)
      raise "Node.js is not installed or not in PATH. Install it from https://nodejs.org (detected: '#{node_version}')"
    end
    Rails.logger.info "Node.js #{node_version} detected"

    # Detect pnpm (v6+)
    pnpm_version = `pnpm --version 2>&1`.strip
    unless $?.success? && pnpm_version.match?(/^\d+\.\d+/)
      raise "pnpm is not installed or not in PATH. Install it with: npm install -g pnpm (detected: '#{pnpm_version}')"
    end

    major = pnpm_version.split(".").first.to_i
    unless major >= 6
      raise "pnpm v6+ is required, but found v#{pnpm_version}. Upgrade with: npm install -g pnpm"
    end
    Rails.logger.info "pnpm v#{pnpm_version} detected"

    # Install dependencies
    unless system("pnpm install --frozen-lockfile")
      raise "pnpm install --frozen-lockfile failed (exit code #{$?.exitstatus}). " \
            "Run 'pnpm install' locally and commit the updated lockfile."
    end
  end
end

Rake::Task["assets:precompile"].enhance(["assets:install_dependencies"])