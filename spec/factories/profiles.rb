# frozen_string_literal: true

# spec/factories/profiles.rb

FactoryBot.define do
  factory :profile do
    user # Asociamos automáticamente el perfil con un usuario (usando una secuencia automática si es necesario)
    name { Faker::Name.name }
    profile_type { "user" } # Ajusta el tipo de perfil según tus necesidades
    avatar_id { "coolCat" }
  end
end
