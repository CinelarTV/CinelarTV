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
    it 'has javascripts register' do
      expect(described_class.javascripts).to be_a(Set)
      expect(described_class.respond_to?(:register_javascript)).to be true
    end

    it 'has stylesheets register' do
      expect(described_class.stylesheets).to be_a(Hash)
      expect(described_class.respond_to?(:register_stylesheet)).to be true
    end

    it 'has seed_data register' do
      expect(described_class.seed_data).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(described_class.respond_to?(:register_seed_data)).to be true
    end

    it 'has filtered registers for various plugin data' do
      filtered_registers = [
        :public_user_custom_fields,
        :staff_user_custom_fields,
        :api_key_scope_mappings,
        :admin_menu_items,
        :user_menu_items,
        :dashboard_widgets,
        :content_scopes,
        :notification_types,
        :permission_types
      ]
      
      filtered_registers.each do |register|
        expect(described_class.respond_to?(register)).to be true
        expect(described_class.respond_to?("register_#{register.to_s.singularize}")).to be true
      end
    end
  end

  describe '.clear_all' do
    it 'clears all registers' do
      # Add some data to registers
      described_class.register_javascript('test.js')
      described_class.register_stylesheet('test.css', 'screen')
      described_class.register_seed_data('test', 'value')
      
      enabled_plugin = double('Plugin', enabled?: true)
      described_class.register_public_user_custom_field('test_field', enabled_plugin)
      
      # Clear all registers
      described_class.clear_all
      
      # Check that registers are cleared
      expect(described_class.javascripts).to be_empty
      expect(described_class.stylesheets).to be_empty
      expect(described_class.seed_data).to be_empty
      expect(described_class.public_user_custom_fields).to be_empty
    end
  end

  describe '.reset!' do
    it 'clears and reinitializes all registers' do
      # Add some data to registers
      described_class.register_javascript('test.js')
      
      # Reset registry
      described_class.reset!
      
      # Should still have the registers defined
      expect(described_class.respond_to?(:javascripts)).to be true
      expect(described_class.respond_to?(:register_javascript)).to be true
      expect(described_class.javascripts).to be_a(Set)
      expect(described_class.javascripts).to be_empty
    end
  end
end
