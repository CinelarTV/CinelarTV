# frozen_string_literal: true

module Plugin
  class Instance
    attr_accessor :path, :metadata, :enabled_site_setting
    attr_reader :initializers

    def self.find_all(parent_path)
      Dir["#{parent_path}/*/plugin.rb"].sort.map { |path| parse_from_source(path) }
    end

    def self.parse_from_source(path)
      instance = new
      instance.path = path
      instance.metadata = Plugin::Metadata.parse(File.read(path))
      instance
    end

    def initialize
      @initializers = []
    end

    def name
      metadata&.name
    end

    def enabled?
      return true unless @enabled_site_setting
      return true unless defined?(::SiteSetting)
      return true unless ::SiteSetting.respond_to?(@enabled_site_setting)
      
      ::SiteSetting.send(@enabled_site_setting)
    rescue StandardError => e
      Rails.logger.debug("[Plugin:#{name}] Could not check enabled setting #{@enabled_site_setting}: #{e.message}")
      true
    end

    def configurable?
      true
    end

    def activate!
      return unless metadata&.valid?
      
      # Check version compatibility
      app_version = CinelarTV::Application::Version::FULL rescue "0.0.1"
      unless metadata.meets_version?(app_version)
        Rails.logger.warn("[Plugin:#{name}] Required version #{metadata.required_version} not met (current: #{app_version})")
        return
      end

      # Execute plugin.rb in the context of this instance
      begin
        instance_eval(File.read(path), path)
      rescue StandardError => e
        Rails.logger.error("[Plugin:#{name}] Failed to load: #{e.message}")
        return
      end

      # Register assets
      register_assets
      
      # Add migration paths
      add_migration_paths
      
      # Add rake task paths
      add_rake_task_paths
      
      # Create public symlink if needed
      create_public_symlink
    end

    def after_initialize(&block)
      @initializers ||= []
      @initializers << block
    end

    def notify_after_initialize
      @initializers&.each { |cb| cb.call(self) }
    end

    def enabled_site_setting(setting = nil)
      @enabled_site_setting = setting if setting
      @enabled_site_setting
    end

    def reloadable_patch(plugin = self)
      if Rails.env.development? && defined?(ActiveSupport::Reloader)
        ActiveSupport::Reloader.to_prepare { yield plugin }
      end
      yield plugin
    end

    def add_to_class(class_name, method_name, &block)
      reloadable_patch do |plugin|
        klass = class_name.to_s.classify.constantize rescue class_name.to_s.constantize
        hidden = :"#{method_name}_without_enable_check"
        
        klass.define_method(hidden, &block)
        klass.define_method(method_name) do |*args, **kwargs|
          send(hidden, *args, **kwargs) if plugin.enabled?
        end
      end
    end

    def add_model_callback(klass_name, callback, options = {}, &block)
      reloadable_patch do |plugin|
        klass = klass_name.to_s.classify.constantize rescue klass_name.to_s.constantize
        method_name = "#{plugin.name}_#{klass.name}_#{callback}_#{SecureRandom.hex(4)}".underscore
        hidden = :"#{method_name}_without_enable_check"
        
        klass.define_method(hidden, &block)
        klass.send(callback, **options) do |*args, **kwargs|
          send(hidden, *args, **kwargs) if plugin.enabled?
        end
      end
    end

    def on(event_name, &block)
      AppEvent.on(event_name) { |*args, **kwargs| block.call(*args, **kwargs) if enabled? }
    end

    def register_js(path)
      Rails.logger.debug "[Plugin::Instance] register_js ignored (Vite handles JS): #{path} from #{name}"
    end

    def register_css(path, media = "all")
      Rails.logger.debug "[Plugin::Instance] register_css ignored (Vite handles CSS): #{path} from #{name}"
    end

    def register_asset(file, opts = nil)
      register_css(file)
    end

    private

    def register_assets
      plugin_dir = File.dirname(path)
      Rails.logger.info "[Plugin::Instance] Registering assets for #{name} from #{plugin_dir}"
      
      # Register JavaScripts
      js_dir = File.join(plugin_dir, "assets", "javascripts")
      if Dir.exist?(js_dir)
        Dir.glob(File.join(js_dir, "**", "*.js")).each do |js_file|
          relative_path = js_file.sub(plugin_dir + "/", "")
          Rails.logger.info "[Plugin::Instance] Found JS file: #{js_file} -> #{relative_path}"
          register_js(relative_path)
        end
      else
        Rails.logger.warn "[Plugin::Instance] JS directory not found: #{js_dir}"
      end

      # Register Stylesheets
      css_dir = File.join(plugin_dir, "assets", "stylesheets")
      if Dir.exist?(css_dir)
        Dir.glob(File.join(css_dir, "**", "*.css")).each do |css_file|
          relative_path = css_file.sub(plugin_dir + "/", "")
          Rails.logger.info "[Plugin::Instance] Found CSS file: #{css_file} -> #{relative_path}"
          register_css(relative_path)
        end
      else
        Rails.logger.warn "[Plugin::Instance] CSS directory not found: #{css_dir}"
      end
    end

    def add_migration_paths
      plugin_dir = File.dirname(path)
      migrate_dir = File.join(plugin_dir, "db", "migrate")
      
      if Dir.exist?(migrate_dir)
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths << migrate_dir
      end
    end

    def add_rake_task_paths
      plugin_dir = File.dirname(path)
      tasks_dir = File.join(plugin_dir, "lib", "tasks")
      
      if Dir.exist?(tasks_dir)
        Rake.add_rakelib(tasks_dir)
      end
    end

    def create_public_symlink
      plugin_dir = File.dirname(path)
      public_dir = File.join(plugin_dir, "public")
      target_dir = Rails.root.join("public", "plugins", name)
      
      if Dir.exist?(public_dir)
        # Remove existing symlink or directory
        FileUtils.rm_rf(target_dir) if File.exist?(target_dir)
        
        # Create parent directory if it doesn't exist
        FileUtils.mkdir_p(File.dirname(target_dir))
        
        # Create symlink
        begin
          File.symlink(public_dir, target_dir)
        rescue NotImplementedError
          # Windows doesn't support symlinks without admin privileges
          FileUtils.cp_r(public_dir, target_dir)
        end
      end
    end
  end
end
