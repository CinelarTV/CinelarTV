# frozen_string_literal: true

# spec/factories/user.rb

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password" }
    password_confirmation { "password" }
  end
end