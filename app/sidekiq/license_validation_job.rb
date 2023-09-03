# frozen_string_literal: true
class LicenseValidationJob
  include Sidekiq::Job
  extend MiniScheduler::Schedule

  every 1.minute

  def perform()
    validate_license(SiteSetting.license_key)
  end

  private

  def validate_license(license_key)
    validate_url = "https://api.lemonsqueezy.com/v1/licenses/validate"

    response = HTTParty.post(validate_url, {
      body: { license_key: license_key }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json" },
    })

    if response.code == 200
      data = JSON.parse(response.body)
      if data["valid"]
        # License is valid, you can process the response or update your database accordingly
        Rails.logger.info("License #{license_key} is valid.")
        # Additional processing, e.g., update the license status in your database
      else
        # License is not valid, handle the error accordingly
        Rails.logger.error("License #{license_key} is not valid. Error: #{data["error"]}")
        # Additional error handling, e.g., deactivate the license in your database
      end
    else
      # Handle API request error
      Rails.logger.error("Error while validating license #{license_key}. HTTP Code: #{response.code}")
    end
  rescue StandardError => e
    # Handle other exceptions
    Rails.logger.error("Error while validating license #{license_key}: #{e.message}")
  end
end
