# frozen_string_literal: true

FactoryBot.define do
  factory :watch_party_session, class: "WatchParty::Session" do
    content_id { SecureRandom.uuid }
    host_id { SecureRandom.uuid }
    user_id { SecureRandom.uuid }
    is_playing { false }
    playback_current_time { 0.0 }
  end
end
