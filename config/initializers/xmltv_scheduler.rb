# frozen_string_literal: true

# config/initializers/xmltv_scheduler.rb

Rails.application.config.after_initialize do
  # We use a rescue to ensure that if Redis is not available or 
  # DB is not migrated, it doesn't break the boot process.
  begin
    XmltvFetchJob.setup_schedule
  rescue StandardError => e
    Rails.logger.warn "Failed to setup XMLTV schedule: #{e.message}"
  end
end
