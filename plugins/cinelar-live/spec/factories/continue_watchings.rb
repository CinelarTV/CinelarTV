# frozen_string_literal: true

FactoryBot.define do
  factory :continue_watchings, class: "ContinueWatching" do
    association :profile
    association :content
    progress { 0.0 }
    duration { 7200.0 }
  end
end
