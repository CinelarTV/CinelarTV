# frozen_string_literal: true

Rails.application.config do |config|
  MessageBus.configure(backend: :memory)

  MessageBus.user_id_lookup do |env|
    env["warden"].user&.id || env["rack.session"]["user_id"]
  end
end
