# CinelarTV 🎬

CinelarTV is a powerful open-source platform that allows you to create your own Video on Demand (VOD) streaming platform. Take your audiovisual content to the next level with CinelarTV!

## Key Features 🚀

- 🎥 Stream your video content on-demand.
- 📊 Detailed audience and performance statistics.
- 📜 Easy and customizable content management.
- 🌐 Support for multiple devices and browsers.
- 🌟 RESTful JSON API for seamless integration with other services.


## Installation and Configuration 🛠️

---

TODO

---

## Pre-built Assets

CinelarTV supports downloading precompiled Vite assets from GitHub Releases instead of compiling them locally. This drastically reduces update and deployment times by skipping the asset compilation step.

### How It Works

When `CINELAR_DOWNLOAD_PRE_BUILT_ASSETS=1` is set, `rake assets:precompile` will:

1. Determine the current Git commit SHA
2. Look for a release tagged `prebuilt-<sha>` in the configured GitHub repository
3. Download and extract the prebuilt Vite assets to `public/vite/`
4. Skip local asset compilation entirely

If the release is not found, it **falls back to native compilation** automatically (unless `CINELAR_PREBUILT_STRICT=1` is set).

### Publishing Prebuilt Assets

After tests pass in CI, publish prebuilt assets:

```bash
bundle exec rake assets:publish_prebuilt
```

This will:
1. Run normal asset compilation
2. Package `public/vite/` into a tarball
3. Create a GitHub Release tagged `prebuilt-<sha>`
4. Upload the tarball as a release asset

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CINELAR_DOWNLOAD_PRE_BUILT_ASSETS` | `nil` | Set to `1` to download prebuilt assets instead of compiling |
| `CINELAR_PREBUILT_STRICT` | `nil` | Set to `1` to abort if release not found (no fallback) |
| `PREBUILT_ASSETS_REPOSITORY` | `CinelarTV/cinelar-assets` | GitHub repo for prebuilt asset releases |
| `PREBUILT_ASSETS_RELEASE_PREFIX` | `prebuilt` | Prefix for release tags |
| `GITHUB_TOKEN` | `nil` | GitHub token (required for private repos) |

### Deployment Example

```bash
# Production deploy — skip asset compilation
CINELAR_DOWNLOAD_PRE_BUILT_ASSETS=1 bundle exec rake assets:precompile

# Or via the updater (no changes needed — just set the env var)
CINELAR_DOWNLOAD_PRE_BUILT_ASSETS=1 bundle exec rake db:migrate assets:precompile
```

### CI Workflow

Add a job to publish assets after tests pass:

```yaml
publish-assets:
  runs-on: ubuntu-latest
  needs: [test]
  if: github.ref == 'refs/heads/main'
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    - uses: ruby/setup-ruby@v1
      with:
        bundler-cache: true
    - uses: pnpm/action-setup@v2
      with:
        version: 9
    - uses: actions/setup-node@v4
      with:
        node-version: 20
        cache: pnpm
    - run: pnpm install --frozen-lockfile
    - name: Publish prebuilt assets
      env:
        GITHUB_TOKEN: ${{ secrets.ASSETS_RELEASE_TOKEN }}
        PREBUILT_ASSETS_REPOSITORY: "CinelarTV/cinelar-assets"
      run: bundle exec rake assets:publish_prebuilt
```

## Stack 🛠️
CinelarTV is powered by the following technologies:

Backend: Ruby on Rails 💎

Frontend: Vue 3 (consumes the JSON API) 🖥️

## API Authentication for Mobile/Native Clients 🔐

CinelarTV now provides a complete RESTful API authentication system designed for mobile apps (iOS/Android) and other native clients.

### Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Login with email/username + password, returns OAuth tokens |
| POST | `/api/v1/auth/refresh` | Refresh an expired access token |
| GET | `/api/v1/auth/me` | Get current user with profiles |
| GET | `/api/v1/auth/profile-status` | Check if user has selected a profile |
| POST | `/api/v1/auth/select-profile` | Select an active profile |
| POST | `/api/v1/auth/deassign-profile` | Deselect current profile |
| DELETE | `/api/v1/auth/logout` | Logout and revoke token |

### Quick Example

**Login:**
```bash
curl -X POST https://your-domain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "secret"}'
```

**Get Current User:**
```bash
curl -X GET https://your-domain.com/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

For complete API documentation with examples in JavaScript, Swift, and Kotlin, see: [API_AUTH_DOCUMENTATION.md](API_AUTH_DOCUMENTATION.md)

## Contribution 🤝
We welcome contributions! If you'd like to contribute to CinelarTV, please fork, fix, commit and send a pull request for the maintainers to review and merge into the main code base 😄.

## License 📝
This project is licensed under the MIT License. See the LICENSE file for more details.

## Contact 📧
Have questions or feedback? Feel free to reach out to us at cinelartv@yanquisalexander.me.

---

Thank you for using CinelarTV! We hope you enjoy creating your own Video on Demand streaming platform. 🍿📺