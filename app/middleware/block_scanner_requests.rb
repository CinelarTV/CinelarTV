# frozen_string_literal: true

class BlockScannerRequests
  BLOCKED_PATTERNS = %w[
    .env
    .env.save
    .env.swp
    .env.bak
    .env.local
    .env.old
    .env.production
    .env.development
    .env.test
    .git/config
    .git/HEAD
    .gitignore
    .htaccess
    .htpasswd
    wp-admin
    wp-login.php
    wp-content
    xmlrpc.php
    phpMyAdmin
    phpmyadmin
    cgi-bin
    server-status
    server-info
    actuator
    actuator/env
    actuator/health
    solr
    adminer
    .ssh
    .bash_history
    .DS_Store
    config/database.yml
    config/master.key
    config/secrets.yml
    config/credentials.yml.enc
    backup
    db.sql
    dump.sql
    .aws/credentials
    .docker/env
    jmx-console
    web-console
    console
    manager/html
  ].freeze

  SCANNER_REGEX = /\.(env|git|svn|bak|swp|old|save|sql|dump|log)\b/i

  AI_PROXY_PATTERN = %r{(/anthropic)?/v1/(messages|chat/completions)}i

  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"]

    if ai_proxy_attempt?(path)
      [418, { "Content-Type" => "application/json" }, [teapot_response(env)]]
    elsif blocked?(path.downcase)
      [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
    else
      @app.call(env)
    end
  end

  private

  def blocked?(path)
    return true if SCANNER_REGEX.match?(path)

    BLOCKED_PATTERNS.any? { |pattern| path.include?(pattern) }
  end

  def ai_proxy_attempt?(path)
    AI_PROXY_PATTERN.match?(path)
  end

  def teapot_response(env)
    accept = env["HTTP_ACCEPT_LANGUAGE"].to_s.downcase
    if accept.start_with?("es")
      '{"error": "Soy una tetera"}'
    else
      '{"error": "I am a teapot"}'
    end
  end
end
