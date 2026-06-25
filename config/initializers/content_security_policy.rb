# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.media_src   :self, :https, :blob
    policy.script_src  :self, :https, "http://www.gstatic.com", "https://www.gstatic.com"
    # Allow @vite/client to hot reload javascript changes in development
    policy.script_src *policy.script_src, :unsafe_eval, :unsafe_inline, "http://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

    # Allow blob: for MSE/EME video playback and web workers
    policy.script_src *policy.script_src, :blob
    policy.worker_src  :self, :blob

    policy.style_src   :self, :https
    # Allow @vite/client to hot reload style changes in development
    policy.style_src *policy.style_src, :unsafe_inline if Rails.env.development?

    # Allow @vite/client to connect via WebSocket in development
    policy.connect_src :self, :https
    policy.connect_src *policy.connect_src, "http://#{ ViteRuby.config.host_with_port }", "ws://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

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
