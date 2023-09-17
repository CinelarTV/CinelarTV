# frozen_string_literal: true

require "sidekiq-scheduler"

class LicenseValidationJob
  include Sidekiq::Job

  def perform
    validate_license(SiteSetting.license_key)
  end

  private

  def validate_license(license_key)
    validate_url = "https://api.lemonsqueezy.com/v1/licenses/validate"

    if license_key.blank? || license_key == "YOUR_LICENSE_KEY"
      raise "License key is blank or not set. Please set your license key in the CinelarTV Wizard."
    end

    response = HTTParty.post(validate_url, {
                               body: { license_key: }.to_json,
                               headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
                             })

    if response.code == 200
      data = JSON.parse(response.body)
      if data["valid"]
        # License is valid, you can process the response or update your database accordingly
        Rails.logger.info("License #{license_key} is valid.")
        CinelarTV.valid_license(true)
      else
        # License is not valid, handle the error accordingly
        Rails.logger.error("License #{license_key} is not valid. Error: #{data['error']}")
        CinelarTV.valid_license(false)
        # Additional error handling, e.g., deactivate the license in your database
      end
    else
      # Handle API request error
      Rails.logger.error("Error while validating license #{license_key}. HTTP Code: #{response.code}. Error: #{response.body}")
      CinelarTV.valid_license(false)
    end
  rescue StandardError => e
    # Handle other exceptions
    Rails.logger.error("Error while validating license #{license_key}: #{e.message}")
    CinelarTV.valid_license(false)
  end
end
