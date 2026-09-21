# frozen_string_literal: true

module Middleware
  # Bypasses OmniAuth for every non-/auth request while building the full
  # provider stack dynamically on each /auth request.  This mirrors the
  # pattern used by Discourse:
  #
  #   • Providers are resolved from `Auth::Registry` at request time, so
  #     enabling / disabling / reconfiguring a provider never requires a
  #     Rails restart.
  #   • We use `middleware_authenticators` (not `enabled_authenticators`)
  #     because credentials are injected by each strategy's `setup` lambda
  #     on every request.  The middleware only needs to know whether the
  #     provider's *toggle* is on.
  #
  # IMPORTANT: For this middleware to intercept /auth/* before Rails routing,
  # it must sit in the Rack stack *above* the Rails router.  Rails registers
  # its router at the very end of the stack, so `config.middleware.use` (which
  # appends) places us correctly — but only if Devise's OmniAuth middleware is
  # NOT also in the stack.  Including `:omniauthable` in the User model causes
  # Devise to insert its own (empty) OmniAuth::Builder that intercepts /auth/*
  # first, finds no matching strategy, and falls through to the router, giving
  # a RoutingError.  The solution is to remove `:omniauthable` from the model
  # and manage the callback routes explicitly (see routes.rb).

  # Backport of Discourse's OmniAuthStrategyCompatPatch.
  # OmniAuth v2 already includes script_name in callback_path, so strategies
  # that manually concatenate script_name produce a duplicated prefix.  This
  # module corrects that at call time and logs a deprecation notice.
  module OmniAuthStrategyCompatPatch
    def callback_url
      result = super
      if script_name.present? && result.include?("#{script_name}#{script_name}")
        result = result.gsub("#{script_name}#{script_name}", script_name)
        Rails.logger.warn(
          "[OmniAuth] Strategy '#{name}' produced a duplicate script_name in " \
          "callback_url. The strategy should be updated for OmniAuth v2 " \
          "compatibility (remove the manual script_name concatenation)."
        )
      end
      result
    end
  end

  # Subclass of OmniAuth::Builder that automatically prepends the
  # OmniAuthStrategyCompatPatch to every strategy that does not already
  # include it.  This mirrors Discourse's PatchedOmniAuthBuilder.
  class PatchedOmniAuthBuilder < OmniAuth::Builder
    def use(strategy, *args, **kwargs, &block)
      if strategy.is_a?(Class) && !strategy.ancestors.include?(OmniAuthStrategyCompatPatch)
        strategy.prepend(OmniAuthStrategyCompatPatch)
      end
      super(strategy, *args, **kwargs, &block)
    end
  end

  class OmniauthBypassMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      path = env["PATH_INFO"].to_s

      # Only intercept /auth/* — everything else falls through to Rails.
      return @app.call(env) unless path.start_with?("/auth")

      # /auth/:provider/token is a mobile token-exchange endpoint handled by
      # OmniAuthCallbacksController entirely within Rails — skip OmniAuth.
      return @app.call(env) if path.match?(%r{\A/auth/[^/]+/token\z})

      # Use `middleware_authenticators`: the strategy is always registered as
      # long as the enable-toggle is on.  Credentials are loaded lazily in
      # the `setup` lambda, so missing credentials won't prevent the strategy
      # from being mounted (they will produce a clear OmniAuth error instead
      # of a misleading RoutingError).
      authenticators = Auth::Registry.middleware_authenticators

      if authenticators.empty?
        Rails.logger.warn(
          "[OmniAuth] #{env['REQUEST_METHOD']} #{path} — " \
          "no authenticators registered, falling through to Rails router"
        )
        return @app.call(env)
      end

      Rails.logger.debug(
        "[OmniAuth] #{env['REQUEST_METHOD']} #{path} — " \
        "providers: #{authenticators.map(&:name).join(', ')}"
      )

      # Dynamically allow GET when only one provider is enabled, mirroring
      # Discourse's single-provider / no-interaction logic.  With multiple
      # providers a POST + CSRF token is always required (OmniAuth 2.x default).
      only_one_provider = authenticators.size == 1
      OmniAuth.config.allowed_request_methods = only_one_provider ? %i[get post] : [:post]

      omniauth = PatchedOmniAuthBuilder.new(@app) do
        authenticators.each { |auth| auth.register_middleware(self) }
      end

      omniauth.call(env)
    end
  end
end
