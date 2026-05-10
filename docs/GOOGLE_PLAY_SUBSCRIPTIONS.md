# Google Play Subscriptions Integration (CinelarTV)

This document describes how to configure and test the Google Play Subscriptions provider integrated into CinelarTV.

Prerequisites
- A Google Cloud service account with the `Android Publisher` / `androidpublisher` scope.
- Play Console access and a published (or test) subscription product.
- A publicly accessible webhook endpoint for Pub/Sub push (or use a Pub/Sub push-to-HTTP forwarder).

Setup
1. Run the migration to add Google Play fields to `user_subscriptions`:

```bash
bin/rails db:migrate
```

2. Configure Site Settings (Admin UI or via rails console):
- `enable_google_play_provider` => true
- `google_play_service_account_json` => Paste the JSON key contents of the service account (secret)
- `google_play_package_name` => com.example.yourapp (optional; if not present the package name included in the SA will be used)
- `google_play_pubsub_verification_token` => (optional) a shared token for simple verification
- `google_play_webhook_endpoint` => (optional) expected audience / endpoint string used for OIDC verification

3. Client flow (recommended):
- After a successful in-app purchase on Android, send the `purchaseToken`, `productId` and `packageName` to the server endpoint `POST /account/billing/subscribe`.
- The server (`GooglePlayProvider#create_subscription!`) validates the token with Google Play Developer API and creates/updates `UserSubscription`.

  Automatic linking from Webhook
  - If the Play Console Pub/Sub notification does not contain a direct user identifier, the provider will attempt to infer the user from:
    - `developerPayload` or `customData` sent by the client at purchase time (recommended). Put a JSON payload containing either `user_id` or `email`, e.g. `{ "user_id": "<uuid>" }`.
    - The purchases API response fields such as `email` or `obfuscatedExternalAccountId` (if you store the latter on the `users` table as `obfuscated_external_account_id`).
  - When the webhook contains an identifier that maps to a `User`, the server will automatically create a `UserSubscription` linked to that `User` and populate status/dates from Google.
  - If no mapping is found, the webhook will only update existing subscriptions (it will not create anonymous subscriptions).

4. Pub/Sub (real-time notifications):
- In Play Console > Monetize > Real-time Developer Notifications configure a Pub/Sub topic.
- Create a subscription that pushes to your webhook URL: `https://your.host/subscriptions/webhooks/google_play`.
- Option A (recommended): Use OIDC-verified push. The provider validates the Bearer token via `https://oauth2.googleapis.com/tokeninfo?id_token=...`.
- Option B: Use a simple verification token and set `google_play_pubsub_verification_token`.

Testing
- Unit tests exist under `spec/services/subscriptions/providers/google_play_provider_spec.rb`.
- To manually test:
  - Use a real `purchaseToken` from an internal test purchase and call the subscribe endpoint.
  - Trigger a Pub/Sub push from the Play Console test interface to verify webhook processing.

Notes & Limitations
- The integration performs a server-side validation using the service account JWT exchange. The service account JSON is required.
- Webhook processing will only update existing local subscriptions. The client should send `purchase_token` immediately after purchase to create the local subscription record.
- Consider using a secret manager (Vault, Google Secret Manager, etc.) instead of storing the service account JSON in SiteSettings for production.

Support
If you want, I can:
- Add full rspec tests (WebMock) that stub Google endpoints.
- Implement automatic linking logic if Pub/Sub messages contain identifying information to find the user.
- Add a small integration script to simulate Pub/Sub pushes for local testing.
