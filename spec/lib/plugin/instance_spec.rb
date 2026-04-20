# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plugin::Instance do
  let(:plugin_path) { Rails.root.join('plugins', 'test-plugin', 'plugin.rb') }
  let(:plugin_content) do
    <<~RUBY
      # name: test-plugin
      # version: 1.0.0
      # authors: John Doe
      # url: https://github.com/example/test-plugin
      
      enabled_site_setting :test_plugin_enabled
      
      after_initialize do
        add_to_class(:user, :test_method) do
          "test data from plugin"
        end
      end
    RUBY
  end

  before do
    # Create test plugin directory and file
    FileUtils.mkdir_p(File.dirname(plugin_path))
    File.write(plugin_path, plugin_content)
  end

  after do
    # Clean up test plugin
    FileUtils.rm_rf(File.dirname(plugin_path))
  end

  describe '.find_all' do
    it 'discovers plugins in the directory' do
      plugins = described_class.find_all(Rails.root.join('plugins').to_s)
      
      expect(plugins).to be_an(Array)
      expect(plugins.size).to be >= 1
      
      test_plugin = plugins.find { |p| p.name == 'test-plugin' }
      expect(test_plugin).to be_present
      expect(test_plugin.path).to eq(plugin_path.to_s)
    end

    it 'returns plugins in alphabetical order' do
      # Create another test plugin
      another_plugin_path = Rails.root.join('plugins', 'another-plugin', 'plugin.rb')
      FileUtils.mkdir_p(File.dirname(another_plugin_path))
      File.write(another_plugin_path, "# name: another-plugin\n# version: 1.0.0\n")

      begin
        plugins = described_class.find_all(Rails.root.join('plugins').to_s)
        plugin_names = plugins.map(&:name)
        
        expect(plugin_names.index('another-plugin')).to be < plugin_names.index('test-plugin')
      ensure
        FileUtils.rm_rf(File.dirname(another_plugin_path))
      end
    end
  end

  describe '.parse_from_source' do
    it 'creates instance from plugin file' do
      instance = described_class.parse_from_source(plugin_path.to_s)
      
      expect(instance).to be_a(described_class)
      expect(instance.path).to eq(plugin_path.to_s)
      expect(instance.metadata).to be_a(Plugin::Metadata)
      expect(instance.metadata.name).to eq('test-plugin')
    end
  end

  describe '#name' do
    it 'returns metadata name' do
      instance = described_class.parse_from_source(plugin_path.to_s)
      expect(instance.name).to eq('test-plugin')
    end
  end

  describe '#enabled?' do
    let(:instance) { described_class.parse_from_source(plugin_path.to_s) }

    before do
      instance.activate!
    end

    context 'when enabled_site_setting is not set' do
      it 'returns true' do
        instance.enabled_site_setting = nil
        expect(instance.enabled?).to be true
      end
    end

    context 'when SiteSetting is not defined' do
      it 'returns true' do
        hide_const('SiteSetting')
        expect(instance.enabled?).to be true
      end
    end

    context 'when SiteSetting exists and responds to setting' do
      it 'returns SiteSetting value' do
        allow(SiteSetting).to receive(:respond_to?).with(:test_plugin_enabled).and_return(true)
        allow(SiteSetting).to receive(:test_plugin_enabled).and_return(false)
        
        expect(instance.enabled?).to be false
      end
    end

    context 'when SiteSetting exists but does not respond to setting' do
      it 'returns true' do
        allow(SiteSetting).to receive(:respond_to?).with(:test_plugin_enabled).and_return(false)
        
        expect(instance.enabled?).to be true
      end
    end
  end

  describe '#add_to_class' do
    let(:instance) { described_class.parse_from_source(plugin_path.to_s) }

    before do
      instance.activate!
    end

    it 'adds method to class with enable check' do
      # Define a test class
      test_class = Class.new do
        def self.name
          'TestUser'
        end
      end
      
      stub_const('User', test_class)
      
      instance.add_to_class(:user, :plugin_test_method) do
        "plugin method result"
      end
      
      user_instance = test_class.new
      
      # When plugin is enabled, method should work
      allow(instance).to receive(:enabled?).and_return(true)
      expect(user_instance.plugin_test_method).to eq("plugin method result")
      
      # When plugin is disabled, method should return nil
      allow(instance).to receive(:enabled?).and_return(false)
      expect(user_instance.plugin_test_method).to be_nil
    end
  end

  describe '#add_model_callback' do
    let(:instance) { described_class.parse_from_source(plugin_path.to_s) }

    before do
      instance.activate!
    end

    it 'adds callback to model with enable check' do
      # Define a test model class
      test_class = Class.new do
        extend ActiveSupport::Callbacks
        
        define_callbacks :create
        
        def self.create
          run_callbacks :create do
            "created"
          end
        end
        
        def self.name
          'TestModel'
        end
      end
      
      stub_const('TestModel', test_class)
      
      callback_executed = false
      
      instance.add_model_callback(:test_model, :after_create) do
        callback_executed = true
      end
      
      # When plugin is enabled, callback should execute
      allow(instance).to receive(:enabled?).and_return(true)
      test_class.create
      expect(callback_executed).to be true
      
      # Reset for disabled test
      callback_executed = false
      allow(instance).to receive(:enabled?).and_return(false)
      test_class.create
      expect(callback_executed).to be false
    end
  end

  describe '#activate!' do
    let(:instance) { described_class.parse_from_source(plugin_path.to_s) }

    it 'executes plugin.rb in instance context' do
      instance.activate!
      
      expect(instance.enabled_site_setting).to eq(:test_plugin_enabled)
      expect(instance.initializers).not_to be_empty
    end

    it 'handles version requirements' do
      # Create plugin with version requirement
      version_plugin_path = Rails.root.join('plugins', 'version-plugin', 'plugin.rb')
      FileUtils.mkdir_p(File.dirname(version_plugin_path))
      
      begin
        File.write(version_plugin_path, <<~RUBY)
          # name: version-plugin
          # version: 1.0.0
          # required_version: 999.0.0
        RUBY
        
        version_instance = described_class.parse_from_source(version_plugin_path.to_s)
        
        # Should log warning and not activate
        expect(Rails.logger).to receive(:warn).with(/Required version 999.0.0 not met/)
        version_instance.activate!
        
        expect(version_instance.initializers).to be_empty
      ensure
        FileUtils.rm_rf(File.dirname(version_plugin_path))
      end
    end
  end

  describe '#after_initialize' do
    let(:instance) { described_class.parse_from_source(plugin_path.to_s) }

    it 'registers initializer blocks' do
      block_executed = false
      
      instance.after_initialize do
        block_executed = true
      end
      
      instance.notify_after_initialize
      
      expect(block_executed).to be true
    end
  end
end
