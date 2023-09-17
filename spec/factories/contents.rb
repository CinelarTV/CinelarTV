# frozen_string_literal: true

# spec/factories/content.rb

FactoryBot.define do
  factory :content do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    banner { Faker::Internet.url }
    cover { Faker::Internet.url }
    content_type { %w[MOVIE TV_SHOW].sample }
    url { Faker::Internet.url }
    year { Faker::Number.between(from: 1900, to: Time.now.year) }
    trailer_url { Faker::Internet.url }
    available { true } # Puedes ajustar el valor predeterminado según tus necesidades
  end
end
