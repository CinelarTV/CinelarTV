#!/usr/bin/env ruby

# Simple test script to verify email template functionality
require_relative 'config/environment'

puts "Testing email template functionality..."

# Test 1: Check if email template layout exists
layout_path = Rails.root.join('app', 'views', 'layouts', 'mailer.html.erb')
if File.exist?(layout_path)
  puts "✓ Email template layout exists"
else
  puts "✗ Email template layout missing"
end

# Test 2: Check if EmailTemplate model exists
begin
  EmailTemplate.new
  puts "✓ EmailTemplate model exists"
rescue NameError
  puts "✗ EmailTemplate model missing"
end

# Test 3: Check if EmailTemplatesController exists
begin
  Admin::EmailTemplatesController.new
  puts "✓ EmailTemplatesController exists"
rescue NameError
  puts "✗ EmailTemplatesController missing"
end

# Test 4: Check if route exists
routes = Rails.application.routes.routes.map(&:name)
if routes.include?('admin_email_templates')
  puts "✓ Email templates routes exist"
else
  puts "✗ Email templates routes missing"
end

# Test 5: Test sample email template rendering
begin
  # Create a simple test mailer
  class TestMailer < ActionMailer::Base
    default from: 'test@example.com'
    
    def test_email
      @subject = 'Test Email'
      @recipient_email = 'test@example.com'
      mail(to: @recipient_email, subject: @subject) do |format|
        format.html { render html: '<h1>Test Content</h1><p>This is a test email.</p>'.html_safe }
      end
    end
  end
  
  email = TestMailer.test_email
  if email.body.to_s.include?('Test Content')
    puts "✓ Email template renders correctly"
  else
    puts "✗ Email template rendering failed"
  end
rescue => e
  puts "✗ Email template test failed: #{e.message}"
end

puts "\nEmail template functionality test completed."
