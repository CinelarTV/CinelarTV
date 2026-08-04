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
    backup.sql
    backup.zip
    backup.tar
    backup.gz
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

  # Patrones que además de bloquearse, se responden con 418 (tetera)
  # en vez de 404: intentos de proxy hacia IA, y escaneos típicos
  # de stacks PHP/ASP/JSP que buscan endpoints ejecutables.
  TEAPOT_PATTERN = %r{
    (/anthropic)?/v1/(messages|chat/completions) |
    \.(php\d?|phtml|asp|aspx|jsp)\b
  }ix.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"]
    downcased = path.downcase

    if teapot_attempt?(downcased)
      [418, { "Content-Type" => "application/json" }, [teapot_response(env)]]
    elsif blocked?(downcased)
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

  def teapot_attempt?(path)
    TEAPOT_PATTERN.match?(path)
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