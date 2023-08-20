# frozen_string_literal: true

# app/validators/allowed_values_validator.rb
class AllowedValuesValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      allowed_values = options[:allowed_values]
      unless allowed_values.include?(value)
        record.errors.add(attribute, :allowed_values, values: allowed_values.join(', '))
      end
    end
  end
  