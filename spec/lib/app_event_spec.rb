# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppEvent do
  before do
    # Clear all events before each test
    described_class.clear
  end

  describe '.on' do
    it 'registers callback for event' do
      callback_executed = false
      
      described_class.on(:test_event) do
        callback_executed = true
      end
      
      described_class.trigger(:test_event)
      
      expect(callback_executed).to be true
    end

    it 'registers multiple callbacks for same event' do
      callback1_executed = false
      callback2_executed = false
      
      described_class.on(:test_event) do
        callback1_executed = true
      end
      
      described_class.on(:test_event) do
        callback2_executed = true
      end
      
      described_class.trigger(:test_event)
      
      expect(callback1_executed).to be true
      expect(callback2_executed).to be true
    end
  end

  describe '.trigger' do
    it 'passes arguments to callbacks' do
      received_args = nil
      received_kwargs = nil
      
      described_class.on(:test_event) do |*args, **kwargs|
        received_args = args
        received_kwargs = kwargs
      end
      
      described_class.trigger(:test_event, 'arg1', 'arg2', key1: 'value1', key2: 'value2')
      
      expect(received_args).to eq(['arg1', 'arg2'])
      expect(received_kwargs).to eq({ key1: 'value1', key2: 'value2' })
    end

    it 'triggers only callbacks for specific event' do
      event1_executed = false
      event2_executed = false
      
      described_class.on(:event1) do
        event1_executed = true
      end
      
      described_class.on(:event2) do
        event2_executed = true
      end
      
      described_class.trigger(:event1)
      
      expect(event1_executed).to be true
      expect(event2_executed).to be false
    end

    it 'handles events with no callbacks gracefully' do
      expect { described_class.trigger(:nonexistent_event) }.not_to raise_error
    end
  end

  describe '.off' do
    it 'removes specific callback' do
      callback_executed = false
      callback = proc { callback_executed = true }
      
      described_class.on(:test_event, &callback)
      described_class.off(:test_event, &callback)
      described_class.trigger(:test_event)
      
      expect(callback_executed).to be false
    end

    it 'removes only the specified callback' do
      callback1_executed = false
      callback2_executed = false
      callback1 = proc { callback1_executed = true }
      callback2 = proc { callback2_executed = true }
      
      described_class.on(:test_event, &callback1)
      described_class.on(:test_event, &callback2)
      described_class.off(:test_event, &callback1)
      described_class.trigger(:test_event)
      
      expect(callback1_executed).to be false
      expect(callback2_executed = true)
    end
  end

  describe '.clear' do
    it 'clears all events when no event name specified' do
      described_class.on(:event1) { }
      described_class.on(:event2) { }
      
      described_class.clear
      
      expect(described_class.events).to be_empty
    end

    it 'clears specific event when event name specified' do
      described_class.on(:event1) { }
      described_class.on(:event2) { }
      
      described_class.clear(:event1)
      
      expect(described_class.events).to include(:event2)
      expect(described_class.events).not_to include(:event1)
    end
  end

  describe '.listeners' do
    it 'returns number of listeners for event' do
      expect(described_class.listeners(:test_event)).to eq(0)
      
      described_class.on(:test_event) { }
      expect(described_class.listeners(:test_event)).to eq(1)
      
      described_class.on(:test_event) { }
      expect(described_class.listeners(:test_event)).to eq(2)
    end

    it 'returns 0 for events with no listeners' do
      expect(described_class.listeners(:nonexistent_event)).to eq(0)
    end
  end

  describe '.events' do
    it 'returns list of all registered events' do
      described_class.on(:event1) { }
      described_class.on(:event2) { }
      
      expect(described_class.events).to contain_exactly(:event1, :event2)
    end

    it 'returns empty array when no events registered' do
      expect(described_class.events).to be_empty
    end
  end
end
