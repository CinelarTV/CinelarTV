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

  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"].downcase

    if blocked?(path)
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
end
