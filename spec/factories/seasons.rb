# frozen_string_literal: true

FactoryBot.define do
  factory :season do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    position { 1 }
    association :content
  end
end
