# frozen_string_literal: true

FactoryBot.define do
  factory :episode do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    position { 1 }
    association :season
  end
end
