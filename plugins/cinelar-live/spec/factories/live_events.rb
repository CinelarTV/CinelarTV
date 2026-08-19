# frozen_string_literal: true

FactoryBot.define do
  factory :live_event, class: "Live::Event" do
    association :content, factory: :content
    association :organizer, factory: :user
    title { Faker::Movie.title }
    description { Faker::Lorem.paragraph }
    starts_at { 1.hour.from_now }
    status { :scheduled }
    is_public { true }
  end
end
