# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# Parse a list of CSP source expressions from a pipe/comma/newline-delimited string.
# Supported formats:
#   - Full URL:    http://example.com:8080  →  http://example.com:8080
#   - Hostname:    example.com              →  example.com
#   - Wildcard:    *.example.com            →  *.example.com
def parse_csp_hosts(raw)
  return [] if raw.blank?

  raw.to_s.split(/[|,\n]/).filter_map do |entry|
    host = entry.strip.downcase
    next if host.blank?

    host
  end
end

Rails.application.configure do
  config.content_security_policy do |policy, _request|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.media_src   :self, :https, :blob
    policy.script_src  :self, :https, "http://www.gstatic.com", "https://www.gstatic.com"
    # Allow @vite/client to hot reload javascript changes in development
    policy.script_src *policy.script_src, :unsafe_eval, :unsafe_inline, "http://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

    # Allow blob: for MSE/EME video playback and web workers
    policy.script_src *policy.script_src, :blob
    policy.worker_src  :self, :blob

    policy.style_src   :self, :https, :unsafe_inline

    # Allow @vite/client to connect via WebSocket in development
    policy.connect_src :self, :https
    policy.connect_src *policy.connect_src, "http://#{ ViteRuby.config.host_with_port }", "ws://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

    # Dynamically add CSP media-src sources from SiteSetting.
    # This lets admins allow external HTTP/HTTPS media hosts without
    # editing code or broadening the policy to include :http.
    begin
      allowed_media_hosts = parse_csp_hosts(SiteSetting.csp_allowed_media_hosts)
      allowed_media_hosts.each do |host|
        policy.media_src host
      end
    rescue StandardError => e
      Rails.logger.warn("CSP: Failed to load allowed media hosts from SiteSetting: #{e.message}")
    end

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap and inline scripts
  if Rails.env.development?
    config.content_security_policy_nonce_generator = nil
    config.content_security_policy_nonce_directives = []
  else
    config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
    config.content_security_policy_nonce_directives = %w(script-src)
  end

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
