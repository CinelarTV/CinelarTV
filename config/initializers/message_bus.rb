# frozen_string_literal: true

# config/initializers/message_bus.rb

# MessageBus.configure(backend: :memory)

MessageBus.user_id_lookup do |env|
  # Get current profile from the session
  request = Rack::Request.new(env)
  Rails.logger.info("MessageBus user_id_lookup: #{request.session[:current_profile_id]}")
  if request.session[:current_profile_id].present?
    request.session[:current_profile_id]
  else
    -1
  end
end
