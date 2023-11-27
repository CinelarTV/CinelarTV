# frozen_string_literal: true

# app/serializers/current_user_serializer.rb
class CurrentUserSerializer < ApplicationSerializer
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::AssetUrlHelper

  attributes :id,
             :email,
             :username,
             :customer_id,
             :created_at,
             :updated_at

  attribute :profiles, if: :include_profiles?
  attribute :current_profile, if: :include_profiles?
  attribute :admin

  def include_profiles?
    @options[:include_profiles]
  end

  def current_profile
    object.profiles.find_by(id: @options[:current_profile_id])
  end

  def admin
    object.is_admin?
  end

  def profiles
    object.profiles
  end
end
