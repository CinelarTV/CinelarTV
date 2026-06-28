# frozen_string_literal: true

# spec/factories/watch_sessions.rb

FactoryBot.define do
  factory :watch_session do
    profile
    content
    episode { nil }
    started_at { Time.current }
    ended_at { nil }
    duration_watched { 0 }
    total_duration { 3600 }
    completed { false }
    country_code { "US" }

    trait :completed do
      completed { true }
      ended_at { Time.current }
      duration_watched { 3600 }
    end

    trait :active do
      ended_at { nil }
    end
  end
end
