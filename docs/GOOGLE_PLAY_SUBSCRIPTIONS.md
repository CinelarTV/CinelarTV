# Google Play Subscriptions Integration (CinelarTV)

This document describes the Android subscription flow for CinelarTV.

Google Play is the mobile subscription provider. The mobile app starts the in-app purchase, CinelarTV verifies the purchase token with the Google Play Developer API, and Google Play Real-time Developer Notifications are delivered through Google Pub/Sub to the existing subscription webhook pipeline.

## Site Settings

| Setting | Description |
| --- | --- |
| `enable_google_play_provider` | Enables Google Play as a subscription provider. |
| `google_play_package_name` | Android package name, for example `tv.cinelar.app`. |
| `google_play_subscription_product_id` | The single Google Play subscription product ID used by the app. |
| `google_play_service_account_json` | Service account JSON with Android Publisher API access. |
| `google_play_pubsub_verify_oidc` | Enables OIDC JWT verification for Pub/Sub push requests. |
| `google_play_pubsub_audience` | Expected Pub/Sub OIDC audience. Usually the webhook URL. |

## Runtime Flow

1. The Android app fetches `google_play_subscription_product_id` from site settings.
2. The Android app calls Google Play Billing for that product.
3. The app sends `purchase_token`, `product_id`, and `provider: "google_play"` to `POST /account/billing/subscribe`.
4. CinelarTV verifies the token with the Google Play Developer API.
5. CinelarTV creates or updates the user's `UserSubscription`.
6. The app acknowledges the transaction only after the backend responds successfully.
7. Google Play sends Real-time Developer Notifications to Pub/Sub.
8. Pub/Sub pushes the event to `POST /subscriptions/webhooks/google_play`.
9. `ProcessSubscriptionWebhookJob` calls `GooglePlayProvider#process_webhook!`.
10. The provider fetches the current subscription state from Google Play and updates the local subscription.

## Pub/Sub Push Payload

Google Pub/Sub push requests should target:

```text
POST https://your-cinelartv-domain/subscriptions/webhooks/google_play
```

The pushed message data is base64-encoded JSON from Google Play. CinelarTV expects `subscriptionNotification.purchaseToken` and `subscriptionNotification.subscriptionId`, then verifies the current state with Google before changing local access.

## Notes

- CinelarTV supports one Google Play subscription product at a time.
- Web subscription providers such as Mercado Pago and Lemon Squeezy remain separate checkout providers.
- Google Play products are managed in Google Play Console, not in the CinelarTV admin plan creator.
- Mobile subscription events are handled directly through Google Play and Pub/Sub.
