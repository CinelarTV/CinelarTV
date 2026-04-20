# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plugin::Metadata do
  describe '.parse' do
    context 'with valid metadata' do
      let(:content) do
        <<~RUBY
          # frozen_string_literal: true
          
          # name: test-plugin
          # version: 1.0.0
          # authors: John Doe
          # url: https://github.com/example/test-plugin
          # required_version: 2.0.0
          
          module TestPlugin
            # Plugin code here
          end
        RUBY
      end

      it 'parses all fields correctly' do
        metadata = described_class.parse(content)
        
        expect(metadata.name).to eq('test-plugin')
        expect(metadata.version).to eq('1.0.0')
        expect(metadata.authors).to eq('John Doe')
        expect(metadata.url).to eq('https://github.com/example/test-plugin')
        expect(metadata.required_version).to eq('2.0.0')
      end
    end

    context 'with partial metadata' do
      let(:content) do
        <<~RUBY
          # name: partial-plugin
          # version: 0.1.0
          
          module PartialPlugin
            # Plugin code
          end
        RUBY
      end

      it 'parses available fields and leaves others nil' do
        metadata = described_class.parse(content)
        
        expect(metadata.name).to eq('partial-plugin')
        expect(metadata.version).to eq('0.1.0')
        expect(metadata.authors).to be_nil
        expect(metadata.url).to be_nil
        expect(metadata.required_version).to be_nil
      end
    end

    context 'with no metadata' do
      let(:content) do
        <<~RUBY
          module NoMetadataPlugin
            # Plugin code
          end
        RUBY
      end

      it 'returns empty metadata' do
        metadata = described_class.parse(content)
        
        expect(metadata.name).to be_nil
        expect(metadata.version).to be_nil
        expect(metadata.authors).to be_nil
        expect(metadata.url).to be_nil
        expect(metadata.required_version).to be_nil
      end
    end

    context 'stopping at first non-comment line' do
      let(:content) do
        <<~RUBY
          # name: stop-test-plugin
          # version: 1.0.0
          
          module StopTestPlugin
            # This should not be parsed as metadata
            # authors: Jane Doe
          end
        RUBY
      end

      it 'stops parsing at first non-comment line' do
        metadata = described_class.parse(content)
        
        expect(metadata.name).to eq('stop-test-plugin')
        expect(metadata.version).to eq('1.0.0')
        expect(metadata.authors).to be_nil
      end
    end
  end

  describe '#valid?' do
    it 'returns true when name is present' do
      metadata = described_class.new
      metadata.name = 'test-plugin'
      
      expect(metadata.valid?).to be true
    end

    it 'returns false when name is nil' do
      metadata = described_class.new
      metadata.name = nil
      
      expect(metadata.valid?).to be false
    end

    it 'returns false when name is empty' do
      metadata = described_class.new
      metadata.name = ''
      
      expect(metadata.valid?).to be false
    end
  end

  describe '#meets_version?' do
    let(:metadata) { described_class.new }

    context 'when required_version is not set' do
      it 'returns true' do
        expect(metadata.meets_version?('1.0.0')).to be true
      end
    end

    context 'when required_version is set' do
      before { metadata.required_version = '2.0.0' }

      it 'returns true when app version meets requirement' do
        expect(metadata.meets_version?('2.0.0')).to be true
        expect(metadata.meets_version?('2.1.0')).to be true
        expect(metadata.meets_version?('3.0.0')).to be true
      end

      it 'returns false when app version does not meet requirement' do
        expect(metadata.meets_version?('1.9.9')).to be false
        expect(metadata.meets_version?('1.0.0')).to be false
      end

      it 'handles invalid version strings gracefully' do
        expect(metadata.meets_version?('invalid')).to be true
        expect(metadata.meets_version?('')).to be true
      end
    end
  end
end
