# frozen_string_literal: true

class XmltvParseJob
  include Sidekiq::Job

  sidekiq_options queue: :xmltv, retry: 1

  def perform(xmltv_source_id)
    source = XmltvSource.find_by(id: xmltv_source_id)
    return unless source&.is_active

    Rails.logger.info "Fetching XMLTV from: #{source.name} (#{source.url})"
    xml_data = source.fetch
    return unless xml_data

    Rails.logger.info "Parsing XMLTV from: #{source.name}"
    programs_count = source.parse(xml_data)
    Rails.logger.info "Parsed #{programs_count} programs from: #{source.name}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "XmltvSource with ID #{xmltv_source_id} not found"
  rescue StandardError => e
    Rails.logger.error "Error parsing XMLTV source #{xmltv_source_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if e.backtrace
  end
end
