# CinelarTV — Agent Guide

## Stack
- **Backend**: Ruby 3.4.4, Rails 7.2 (rack-cors, devise, doorkeeper, sidekiq, active_model_serializers)
- **Frontend**: Vue 3 (Composition API) + Vite 5, TypeScript/TSX, Tailwind CSS 4, Pinia
- **Database**: PostgreSQL (all environments — the sqlite3 default in database.yml is unused)
- **Package manager**: pnpm 9.9.0 with workspaces for `plugins/*`
- **Background jobs**: Sidekiq + sidekiq-scheduler (Redis)
- **Auth**: Devise (web sessions) + Doorkeeper OAuth 2.0 (mobile/native clients)
- **Video**: FFmpeg transcoding, HLS, Vidstack player

## Setup & Dev
```bash
bundle install
pnpm install
bundle exec rails db:create db:migrate db:seed
bundle exec rails server -b 0.0.0.0   # Puma on :3000
bundle exec vite dev                   # Vite dev server on :3036
```

## Key Commands
| Action | Command |
|--------|---------|
| Run all tests | `bundle exec rspec` |
| Single test file | `bundle exec rspec spec/path/to/file_spec.rb` |
| Lint Ruby | `bundle exec rubocop` |
| Security audit | `bundle exec brakeman --no-exit-on-error --skip-files lib/cinelar_tv.rb,lib/updater.rb` |
| Security deps | `bundle audit check --ignore CVE-2015-9284 --update` |
| Build CSS (Tailwind) | `pnpm run build:css` |
| Export i18n JS | `pnpm run i18n:export` (runs `bundle exec rake i18n:js:export`) |
| New plugin | `bundle exec rails plugin:create[name]` |
| Generate plugin | `bin/rails plugin:new` (aliased to plugin:create) |
| Sync translations | `pnpm run i18n:sync` (localazy download + export) |
| Sidekiq (general) | `bundle exec sidekiq -C config/sidekiq.yml` |
| Sidekiq (video) | `bundle exec sidekiq -C config/sidekiq_video.yml` |
| Migrate DB | `bundle exec rails db:migrate` |

## Architecture

### Frontend
- **Entrypoint**: `app/frontend/entrypoints/boot-cinelartv.ts` (loaded via `vite_typescript_tag`)
- **App setup**: `app/frontend/webclient/application.js` — creates Vue app, registers plugins
- **Router**: `app/frontend/webclient/routes/router-map.js` — auto-discovers `*.route.js` + plugin routes dynamically
- **Path aliases**: `@/` → `app/frontend/webclient/`, `@plugins/` → `plugins/`
- **Components**: Mix of `.vue` SFC and `.tsx` (JSX) — both actively used; follow existing file's pattern
- **State**: Pinia stores in `stores/` and `app/services/`

### Backend
- **Routes**: `config/routes.rb` + `config/routes/admin.rb` (via `draw :admin`); plugin routes auto-loaded from `plugins/*/config/routes.rb`
- **Serializers**: `active_model_serializers` (not jbuilder/jsonapi-rb)
- **Dual auth**: `authenticate_user!` checks Doorkeeper token first, falls back to Devise session
- **Devise**: `navigational_formats = []` — JSON requests never get redirected
- **Custom FailureApp**: `lib/devise_failure_app.rb` — renders JSON errors for API auth failures
- **Dev**: `config.hosts.clear` — allows ngrok, cloudflare tunnels, VS Code port forwarding

### Queue Priority
```
video_transcoding (7) > subscriptions (5) > default (3) > xmltv (2)
```
Separate `sidekiq_video.yml` for dedicated transcoding workers (concurrency: 5, no scheduler).

### Plugin System
- **Ruby**: `plugins/*/plugin.rb` with metadata comments (`# name:`, `# version:`), activated via `Plugin::Instance`
- **Rails::Engine**: Plugins can define a `Rails::Engine` with `isolate_namespace` (like Discourse). The engine lives at `lib/<module>/engine.rb` and enables proper autoloading. See `CinelarTV::PluginEngine` base class.
- **Frontend**: Loaded dynamically after Vue mount in `boot-cinelartv.ts` → `loadPlugins()`
- **Frontend outlets**: Components auto-register via `registerPluginOutlet(name, component)` or by placing files in `assets/javascripts/connectors/{outlet-name}/` (convention-based, like Discourse connectors)
- **Event bus**: Frontend event system (`lib/plugin-events.ts`) with `on`, `off`, `emit`, `clear`. PluginAPI exposes `onAppEvent()` / `offAppEvent()` for plugins. Router emits `navigation`; videoplayer emits `playback:play` / `playback:pause`.
- **Auto-registered**: routes, migrations, assets (JS/CSS), rake tasks, models, controllers, dashboard widgets, settings
- **Settings**: Plugins provide `config/settings.yml` (Discourse-style). Legacy `config/site_settings.yml` also supported via `SiteSetting.load_settings`.
- **Compatibility**: Plugins can add `.cinelar-compatibility` file with version constraints (Discourse-style format).
- **Testing**: `spec/support/plugin_spec_helper.rb` provides `with_plugin`, `with_site_setting`, `mock_plugin` helpers.
- **Scaffold**: Run `bundle exec rails plugin:create[name]` to generate a new plugin skeleton.

### i18n
- Source: `config/locales/en.yml` → sync via Localazy + Crowdin
- Frontend: `i18n-js` gem exports to `app/frontend/webclient/i18n/translations.js`
- Run `pnpm run i18n:export` after locale changes
- JsRoutes middleware auto-generates JS route helpers in development

## Testing
- RSpec with FactoryBot (`spec/factories/`), transactional fixtures, Devise controller helpers
- Request specs in `spec/requests/`, model specs in `spec/models/`
- CI runs `rails db:migrate` then `rspec` on PostgreSQL

## Known Quirks
- **database.yml** defaults to `sqlite3` adapter but all envs override to `postgresql` — only PostgreSQL works
- `.env` is gitignored but present in repo for dev convenience; **do not commit secrets**
- CORS initializer reads dynamic `SiteSetting` — may raise on fresh boot before settings exist
- `pnpm` is the only package manager; workspaces manage `plugins/*`
- `assets:precompile` is hooked to `js:routes` (Rakefile)
- Devise `stretches = 1` in test (fast), `12` otherwise
- `config/master.key` and `config/credentials.yml.enc` are gitignored
