# frozen_string_literal: true

module PluginGem
  def self.load(path, name, version, opts = nil)
    opts ||= {}

    gems_path = File.dirname(path) + "/gems/#{RUBY_VERSION}"
    spec_path = gems_path + "/specifications"
    spec_file = spec_path + "/#{name}-#{version}.gemspec"

    unless platform_variants(spec_file).any?(&File.method(:exist?))
      command = "gem install #{name} -v #{version} -i #{gems_path} --no-document --ignore-dependencies --no-user-install"
      command += " --source #{opts[:source]}" if opts[:source]
      puts "[PluginGem] #{command}"

      system(command)
    end

    spec_file_variant = platform_variants(spec_file).find(&File.method(:exist?))
    if spec_file_variant
      Gem.path << gems_path unless Gem.path.include?(gems_path)

      spec = Gem::Specification.load(spec_file_variant)
      if spec
        gem_dir = File.dirname(spec_file_variant.sub("/specifications/", "/gems/#{name}-#{version}/"))
        lib_dir = File.join(gem_dir, "lib")
        $LOAD_PATH.unshift(lib_dir) if Dir.exist?(lib_dir) && !$LOAD_PATH.include?(lib_dir)
      end
    else
      puts "[PluginGem] WARNING: #{name} #{version} could not be installed for plugin #{path}"
    end
  end

  def self.platform_variants(spec_file)
    [
      spec_file,
      "#{spec_file}-ruby",
      "#{spec_file}-#{RUBY_PLATFORM}",
      "#{spec_file}-x86_64-linux",
      "#{spec_file}-aarch64-linux"
    ]
  end
end
