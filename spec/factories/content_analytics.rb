# frozen_string_literal: true

# spec/factories/content_analytics.rb

FactoryBot.define do
  factory :content_analytic do
    content
    total_views { 0 }
    total_seconds_watched { 0 }
    unique_profiles { 0 }
    completion_rate { 0.0 }
    avg_watch_percentage { 0.0 }
    last_watched_at { nil }
  end
end
