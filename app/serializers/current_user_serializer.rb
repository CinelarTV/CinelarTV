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

  attribute :is_subscribed, if: :include_subscription?
  attribute :subscription, if: :include_subscription?
  attribute :profiles, if: :include_profiles?
  attribute :current_profile, if: :include_profiles?
  attribute :admin

  def include_profiles?
    @options[:include_profiles]
  end

  def include_subscription?
    @options.fetch(:include_subscription, true)
  end

  def current_profile
    object.profiles.find_by(id: @options[:current_profile_id])
  end

  def admin
    object.is_admin?
  end

  def is_subscribed
    !!object.is_subscribed?
  end

  def subscription
    object.user_subscriptions.active.first || object.user_subscriptions.last
  end

  def profiles
    object.profiles.as_json(include: :preferences)
  end
end
