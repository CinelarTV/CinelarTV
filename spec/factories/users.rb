# frozen_string_literal: true

# spec/factories/user.rb

require "faker"

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password" }
    password_confirmation { "password" }
    username { Faker::Internet.username }
  end
end
