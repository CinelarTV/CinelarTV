# frozen_string_literal: true

# config/initializers/message_bus.rb

Rails.application.config do |config|
  MessageBus.configure(backend: :memory)

  def setup_message_bus_env(env)
    return if env["__mb"]

    user = nil

    begin
      request = Rack::Request.new(env)

      user = User.find(request.env["warden"].user.id) if request.env["warden"].user
    rescue => e
      Rails.logger.error("Failed to setup message bus env: #{e}")
    end

    user_id = user && user.id

    hash = {
      user_id: user_id,
    }

    env["__mb"] = hash
  end

  MessageBus.user_id_lookup do |env|
    setup_message_bus_env(env)
    env["__mb"][:user_id]
  end
end
