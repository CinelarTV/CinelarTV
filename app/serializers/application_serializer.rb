# frozen_string_literal: true

# Make an application_serializer.rb

# app/serializers/application_serializer.rb

class ApplicationSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
end


