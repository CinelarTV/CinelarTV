namespace :assets do
  desc "Ensures that dependencies required to compile assets are installed"
  task install_dependencies: :environment do
    
    # pnpm v6+
    raise if File.exist?("package.json") && !(system "pnpm install --frozen-lockfile")
  end
end

Rake::Task["assets:precompile"].enhance ["assets:install_dependencies"]