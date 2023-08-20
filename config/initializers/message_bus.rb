# frozen_string_literal: true

Rails.application.config do |config|
    MessageBus.configure(backend: :memory)
end