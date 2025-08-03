# frozen_string_literal: true

class Wizard
  class StepUpdater
    include ActiveModel::Model

    require "uri"
    require "net/http"

    attr_accessor :refresh_required, :fields

    def initialize(current_user, step, fields)
      @current_user = current_user
      @step = step
      @refresh_required = false
      @fields = fields
    end

    def update
      @step.updater.call(self) if @step.present? && @step.updater.present?

      return unless success?

      # Implement logging or any other actions specific to CinelarTV
      Rails.logger.info("Wizard step updated successfully")
    end

    def success?
      @errors.blank?
    end

    def refresh_required?
      @refresh_required
    end

    def update_setting(id, value)
      Rails.logger.warn("Updating setting #{id} to #{value}") # Use Rails.logger.warn for better visibility in logs
      value = value.strip if value.is_a?(String)
      # Implement logic for handling specific settings in CinelarTV
      # For example:
      # if id == :custom_setting
      #   # Custom logic for handling the setting
      # end


      SiteSetting.send("#{id}=", value)
    end

    def apply_setting(id)
      Rails.logger.info("Applying setting #{id}")
      update_setting(id, @fields[id])
    end

    def ensure_changed(id)
      errors.add(id, "") if @fields[id] == SiteSetting.send(id)
    end

    def apply_settings(*ids)
      ids.each do |id|
        apply_setting(id)
      end
    end
  end
end
