# frozen_string_literal: true

module AppEvent
  @callbacks = Hash.new { |h, k| h[k] = [] }

  class << self
    def on(event_name, &block)
      @callbacks[event_name] << block
    end

    def off(event_name, &block)
      @callbacks[event_name].delete(block)
    end

    def trigger(event_name, *args, **kwargs)
      @callbacks[event_name].each { |cb| cb.call(*args, **kwargs) }
    end

    def clear(event_name = nil)
      if event_name
        @callbacks[event_name].clear
      else
        @callbacks.clear
      end
    end

    def listeners(event_name)
      @callbacks[event_name].size
    end

    def events
      @callbacks.keys
    end
  end
end
