# frozen_string_literal: true

# Serve static files from plugins/ directory in development.
# This allows Vite dev server to resolve plugin assets via the @plugins alias.
if Rails.env.development?
  Rails.application.config.middleware.insert_before 0, ActionDispatch::Static,
    Rails.root.join("plugins").to_s,
    headers: { "Cache-Control" => "public, max-age=3600" }
end
