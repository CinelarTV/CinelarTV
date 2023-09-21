# frozen_string_literal: true

# lib/ip_info.rb

require "maxminddb"

class IpInfo
  include Singleton

  def initialize
    open_db(IpInfo.path)
  end

  def open_db(path)
    @loc_mmdb = mmdb_load(File.join(path, "GeoLite2-City.mmdb"))
    @asn_mmdb = mmdb_load(File.join(path, "GeoLite2-ASN.mmdb"))
  end

  def self.path
    @path ||= Rails.root.join("vendor", "data")
  end

  def self.mmdb_path(name)
    File.join(path, "#{name}.mmdb")
  end

  def mmdb_load(filepath)
    begin
      MaxMindDB.new(filepath, MaxMindDB::LOW_MEMORY_FILE_READER)
    rescue Errno::ENOENT => e
      Rails.logger.warn("MaxMindDB (#{filepath}) could not be found: #{e}")
      nil
    rescue => e
      Rails.logger.warn("MaxMindDB (#{filepath}) could not be loaded: #{e}")
      nil
    end
  end

  def lookup(ip, locale: :en, resolve_hostname: false)
    ret = {}
    return ret if ip.blank?

    if @loc_mmdb
      begin
        result = @loc_mmdb.lookup(ip)
        if result&.found?
          ret[:country] = result.country.name(locale) || result.country.name
          ret[:country_code] = result.country.iso_code
          ret[:region] = result.subdivisions.most_specific.name(locale) || result.subdivisions.most_specific.name
          ret[:city] = result.city.name(locale) || result.city.name
          ret[:latitude] = result.location.latitude
          ret[:longitude] = result.location.longitude
          ret[:location] = ret.values_at(:city, :region, :country).reject(&:blank?).uniq.join(", ")

          # used by plugins or API to locate users more accurately
          ret[:geoname_ids] = [
            result.continent.geoname_id,
            result.country.geoname_id,
            result.city.geoname_id,
            *result.subdivisions.map(&:geoname_id),
          ]
          ret[:geoname_ids].compact!
        end
      rescue => e
        Rails.logger.warn("IP #{ip} could not be looked up in MaxMind GeoLite2-City database: #{e}")
      end
    end

    if @asn_mmdb
      begin
        result = @asn_mmdb.lookup(ip)
        if result&.found?
          result = result.to_hash
          ret[:asn] = result["autonomous_system_number"]
          ret[:organization] = result["autonomous_system_organization"]
        end
      rescue => e
        Rails.logger.warn("IP #{ip} could not be looked up in MaxMind GeoLite2-ASN database: #{e}")
      end
    end

    # this can block for quite a while
    # only use it explicitly when needed
    if resolve_hostname
      begin
        result = Resolv::DNS.new.getname(ip)
        ret[:hostname] = result&.to_s
      rescue Resolv::ResolvError
      end
    end

    ret
  end

  def self.open_db(path)
    instance.open_db(path)
  end

  def self.lookup(ip, locale: :en, resolve_hostname: false)
    instance.lookup(ip, locale: locale, resolve_hostname: resolve_hostname)
  end

  def self.name_by_country_code(code, locale: :en)
    raise CinelarTV::NotFound unless code.present?

    country = ISO3166::Country.find_country_by_alpha2(code)
    raise CinelarTV::NotFound unless country

    country.translations[locale.to_s] || country.name
  end
end
