# frozen_string_literal: true

# db/seeds.rb - Seed script for CinelarTV
# Run with: rails db:seed

puts "Seeding database..."

# Create default Doorkeeper application for API auth
unless Doorkeeper::Application.exists?(name: "Default API Client")
  Doorkeeper::Application.create!(
    name: "Default API Client",
    redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
    scopes: "read write",
    confidential: false
  )
  puts "✓ Created default Doorkeeper application"
else
  puts "✓ Default Doorkeeper application already exists"
end

puts "Seeding complete!"
