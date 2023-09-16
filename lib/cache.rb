# frozen_string_literal: true

class Cache
  MAX_CACHE_AGE = 1.day unless defined?(MAX_CACHE_AGE)

  attr_reader :namespace

  def self.supports_cache_versioning?
    false
  end

  def initialize(namespace: "_CACHE")
    @namespace = namespace
  end

  def redis
    @redis ||= Redis.new(db: 1)
  end

  def reconnect
    redis.reconnect
  end

  def keys(pattern = "*")
    redis.scan_each(match: "#{@namespace}:#{pattern}").to_a
  end

  def clear
    keys.each { |k| redis.del(k) }
  end

  def normalize_key(key)
    "#{@namespace}:#{key}"
  end

  def exist?(name)
    key = normalize_key(name)
    redis.exists?(key)
  end

  # this removes a bunch of stuff we do not need like instrumentation and versioning
  def read(name)
    key = normalize_key(name)
    read_entry(key)
  end

  def write(name, value, expires_in: nil)
    write_entry(normalize_key(name), value, expires_in: expires_in)
  end

  def delete(name)
    redis.del(normalize_key(name))
  end

  def fetch(name, expires_in: nil, force: nil, &blk)
    if block_given?
      key = normalize_key(name)
      raw = nil

      raw = redis.get(key) if !force

      if raw
        begin
          Marshal.load(raw) # rubocop:disable Security/MarshalLoad
        rescue => e
          log_first_exception(e)
        end
      else
        val = blk.call
        write_entry(key, val, expires_in: expires_in)
        val
      end
    elsif force
      raise ArgumentError,
            "Missing block: Calling `Cache#fetch` with `force: true` requires a block."
    else
      read(name)
    end
  end

  protected

  def log_first_exception(e)
    if !defined?(@logged_a_warning)
      @logged_a_warning = true
      Rails.logger.warn("Cache read error: #{e.message}")
    end
  end

  def read_entry(key)
    if data = redis.get(key)
      Marshal.load(data) # rubocop:disable Security/MarshalLoad
    end
  rescue => e
    log_first_exception(e)
  end

  def write_entry(key, value, expires_in: nil)
    dumped = Marshal.dump(value)
    expiry = expires_in || MAX_CACHE_AGE
    redis.setex(key, expiry, dumped)
    true
  end
end
