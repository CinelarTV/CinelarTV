# frozen_string_literal: true

Rails.application.config do |config|
  MessageBus.configure(backend: :memory)

  MessageBus.user_id_lookup do |env|
    req = Rack::Request.new(env)
    if req.session && req.session["warden.user.user.key"] && req.session["warden.user.user.key"][0][0]
      user = User.find(req.session["warden.user.user.key"][0][0])
      user.id
      Rails.logger.info "MessageBus.user_id_lookup: #{user.id}"
    end
  end
end
