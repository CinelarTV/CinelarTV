# frozen_string_literal: true

class UserPreferencesController < ApplicationController
  before_action :authenticate_user!

  def index
    profile = current_profile
    unless profile
      render json: { error: "No profile selected" }, status: :unprocessable_entity
      return
    end

    settings = UserPreference.settings_for_access(profile.profile_type)

    response = settings.each_with_object({}) do |setting, memo|
      category = setting[:category]
      memo[category] ||= []

      pref = profile.preferences.find_by(key: setting[:key])
      value = pref ? pref.value : setting[:default]

      memo[category] << {
        key: setting[:key],
        category: category,
        type: setting[:type],
        value: cast_value(value, setting[:type]),
        default: setting[:default],
        readonly: setting[:readonly],
        allowed_values: setting[:allowed_values],
        min: setting[:min],
        max: setting[:max],
        maxlength: setting[:maxlength],
        regex: setting[:regex],
      }
    end

    render json: {
      preferences: response,
      profile_type: profile.profile_type,
    }
  end

  def update
    profile = current_profile
    unless profile
      render json: { error: "No profile selected" }, status: :unprocessable_entity
      return
    end

    preferences_params = params.require(:preferences).permit!.to_h
    result = UserPreference.set_batch(profile, preferences_params)

    if result[:errors].any?
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    else
      render json: { message: "Preferences updated successfully" }, status: :ok
    end
  end

  private

  def cast_value(value, type)
    return nil if value.nil?

    case type
    when "boolean"
      %w[true 1 yes on].include?(value.to_s.downcase)
    when "integer"
      value.to_i
    when "number"
      value.to_f
    else
      value.to_s
    end
  end
end
