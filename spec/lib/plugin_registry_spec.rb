# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PluginRegistry do
  before do
    # Reset registry before each test
    described_class.reset!
  end

  describe '.define_register' do
    it 'creates static register with getter and setter methods' do
      described_class.define_register(:test_register, Set)
      
      # Should have getter method
      expect(described_class.respond_to?(:test_register)).to be true
      expect(described_class.test_register).to be_a(Set)
      
      # Should have setter method
      expect(described_class.respond_to?(:register_test_register)).to be true
      
      # Should be able to add values
      described_class.register_test_register('test_value')
      expect(described_class.test_register).to include('test_value')
    end
  end

  describe '.define_filtered_register' do
    let(:enabled_plugin) { double('Plugin', enabled?: true) }
    let(:disabled_plugin) { double('Plugin', enabled?: false) }

    it 'creates filtered register that only includes enabled plugin values' do
      described_class.define_filtered_register(:filtered_register)
      
      # Should have getter method
      expect(described_class.respond_to?(:filtered_register)).to be true
      
      # Should have setter method
      expect(described_class.respond_to?(:register_filtered_register)).to be true
      
      # Add values from both enabled and disabled plugins
      described_class.register_filtered_register('enabled_value', enabled_plugin)
      described_class.register_filtered_register('disabled_value', disabled_plugin)
      
      # Should only include enabled plugin values
      expect(described_class.filtered_register).to contain_exactly('enabled_value')
      expect(described_class.filtered_register).not_to include('disabled_value')
    end

    it 'removes duplicates from filtered results' do
      described_class.define_filtered_register(:duplicate_register)
      
      # Add same value from multiple enabled plugins
      plugin1 = double('Plugin1', enabled?: true)
      plugin2 = double('Plugin2', enabled?: true)
      
      described_class.register_duplicate_register('duplicate_value', plugin1)
      described_class.register_duplicate_register('duplicate_value', plugin2)
      
      expect(described_class.duplicate_register).to contain_exactly('duplicate_value')
    end
  end

  describe 'predefined registers' do
    it 'has seed_data register' do
      expect(described_class.seed_data).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(described_class.respond_to?(:register_seed_datum)).to be true
    end

    it 'has filtered registers for various plugin data' do
      filtered_registers = [
        :user_profile_fields,
        :content_scopes,
        :admin_menu_items,
        :user_menu_items,
        :dashboard_widgets,
        :video_source_types,
        :live_tv_features,
        :subscription_providers,
        :content_metadata_fields,
        :player_controls,
        :search_filters
      ]
      
      filtered_registers.each do |register|
        expect(described_class.respond_to?(register)).to be true
        expect(described_class.respond_to?("register_#{register.to_s.singularize}")).to be true
      end
    end
  end

  describe '.clear_all' do
    it 'clears all registers' do
      described_class.register_seed_datum('test', 'value')

      enabled_plugin = double('Plugin', enabled?: true)
      described_class.register_admin_menu_item({ name: 'test_item' }, enabled_plugin)

      described_class.clear_all

      expect(described_class.seed_data).to be_empty
      expect(described_class.admin_menu_items).to be_empty
    end
  end

  describe '.reset!' do
    it 'clears and reinitializes all registers' do
      described_class.register_seed_datum('test', 'value')

      described_class.reset!

      expect(described_class.respond_to?(:seed_data)).to be true
      expect(described_class.respond_to?(:register_seed_datum)).to be true
      expect(described_class.seed_data).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(described_class.seed_data).to be_empty
    end
  end
end
