# frozen_string_literal: true

class XmltvSource < ApplicationRecord
  validates :name, presence: true
  validates :url, presence: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" }

  scope :active, -> { where(is_active: true) }

  def fetch
    response = HTTParty.get(url, timeout: 30)
    raise "Failed to fetch XMLTV: #{response.message}" unless response.success?

    update!(
      raw_xml: response.body,
      last_fetched_at: Time.current
    )

    raw_xml
  rescue StandardError => e
    errors.add(:base, "Failed to fetch XMLTV: #{e.message}")
    nil
  end

  def parse(xml_data = nil)
    xml_data ||= fetch
    return nil unless xml_data

    doc = Nokogiri::XML(xml_data)

    # Parse channels and match with our LiveTvChannel records
    channels = doc.css("channel")
    channel_map = channels.each_with_object({}) do |channel, hash|
      hash[channel["id"]] = {
        display_name: channel.at("display-name")&.text,
        icon: channel.at("icon")&.attr("src"),
      }
    end

    # Parse programs
    programs_data = doc.css("programme").map do |programme|
      channel_id = programme["channel"]
      start_time = parse_xmltv_time(programme["start"])
      end_time = parse_xmltv_time(programme["stop"])

      next unless start_time && end_time

      {
        xmltv_id: channel_id,
        title: programme.at("title")&.text || "Sin título",
        description: programme.at("desc")&.text,
        start_time: start_time,
        end_time: end_time,
        icon_url: programme.at("icon")&.attr("src"),
        category: programme.at("category")&.text,
      }
    end.compact

    updated_channel_names = []

    # Remove stale programs within the feed range for each channel before saving fresh data.
    programs_data.group_by { |data| data[:xmltv_id] }.each do |xmltv_channel_id, channel_programs|
      channel = LiveTvChannel.find_by(xmltv_channel_id: xmltv_channel_id)
      next unless channel

      updated_channel_names << channel.name
      start_range = channel_programs.map { |data| data[:start_time] }.min
      end_range = channel_programs.map { |data| data[:end_time] }.max

      channel.tv_programs.where(xmltv_id: xmltv_channel_id)
                     .where(start_time: start_range..end_range)
                     .delete_all

      channel_programs.each do |data|
        channel.tv_programs.create!(
          live_tv_channel_id: channel.id,
          xmltv_id: xmltv_channel_id,
          title: data[:title],
          description: data[:description],
          start_time: data[:start_time],
          end_time: data[:end_time],
          icon_url: data[:icon_url],
          category: data[:category]
        )
      end
    end

    update!(last_parsed_at: Time.current)
    {
      programs_count: programs_data.size,
      channels: updated_channel_names.uniq
    }
  end

  private

  def parse_xmltv_time(time_str)
    return nil unless time_str.present?

    # XMLTV format: YYYYMMDDHHmmSS [+/-HHMM]
    # Example: 20230904120000 +0000
    Time.zone.parse(time_str)
  rescue StandardError
    nil
  end
end
