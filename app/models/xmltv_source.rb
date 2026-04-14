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

    # Create or update programs
    programs_data.each do |data|
      channel = LiveTvChannel.find_by(xmltv_channel_id: data[:xmltv_id])
      next unless channel

      # Find existing program by xmltv_id and time, or create new
      existing = TvProgram.find_by(
        live_tv_channel_id: channel.id,
        xmltv_id: data[:xmltv_id],
        start_time: data[:start_time]
      )

      if existing
        existing.update!(data.except(:xmltv_id))
      else
        TvProgram.create!(
          live_tv_channel_id: channel.id,
          xmltv_id: data[:xmltv_id],
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
    programs_data.size
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
