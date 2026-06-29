# OpenIAP Subscriptions Integration (CinelarTV)

This document describes how to configure and test the OpenIAP Subscriptions provider integrated into CinelarTV.

OpenIAP normalizes Apple App Store Server Notifications v2 and Google Play Real-Time Developer Notifications into a single cross-store event stream. The mobile app consumes events via SDK, while the backend verifies receipts on-demand.

## Prerequisites

- An OpenIAP account and project at https://kit.openiap.dev
- An API key from the OpenIAP dashboard
- Google Play and/or Apple App Store configured in the OpenIAP dashboard

## Setup

### 1. Run the migration

```bash
bin/rails db:migrate
```

This renames `google_product_id` to `iap_product_id` in the `user_subscriptions` table.

### 2. Configure OpenIAP Dashboard

1. Go to https://kit.openiap.dev and sign in
2. Create a project or use an existing one
3. Copy your API key (format: `openiap-kit_<project-key>`)
4. Configure Google Play:
   - Go to **Webhooks** tab
   - Copy the lifecycle webhook URL
   - Paste it into Google Cloud Console > Pub/Sub > Subscription > Push endpoint
   - Also paste into Play Console > Monetize > Real-time developer notifications
5. Configure Apple (when ready):
   - Go to **Webhooks** tab
   - Copy the lifecycle webhook URL
   - Paste into App Store Connect > App Information > App Store Server Notifications

### 3. Configure Site Settings

In the Admin UI or via rails console:

| Setting | Value | Description |
|---------|-------|-------------|
| `enable_open_iap_provider` | `true` | Enable the OpenIAP provider |
| `open_iap_api_key` | `openiap-kit_<your-key>` | Your OpenIAP project API key (secret) |
| `open_iap_base_url` | `https://kit.openiap.dev` | OpenIAP Kit server URL (default) |
| `open_iap_product_id_map` | `{"com.app.plan.monthly": "Monthly Plan"}` | JSON map of product IDs to display names |

## Architecture

```
Google Play / Apple App Store
        ↓ (webhooks)
   OpenIAP Kit Server (normalizes, stores, deduplicates)
        ↓ (SSE stream)
   Mobile App (react-native-iap / flutter_inapp_purchase SDK)
        ↓ (API calls)
   CinelarTV Backend (receipt verification, subscription storage)
```

- **Mobile app** connects to OpenIAP's SSE stream via SDK to receive real-time lifecycle events
- **Mobile app** handles purchases and entitlements locally
- **Backend** verifies receipts via `POST /v1/purchase/verify` when the client reports a purchase
- **Backend** stores subscription records for admin dashboard and cross-device sync

## Client Flow

1. User purchases a subscription in the mobile app (Google Play / App Store)
2. Mobile app sends `purchaseToken`, `productId`, and `store` to `POST /account/billing/subscribe`
3. Backend calls OpenIAP `POST /v1/purchase/verify` with `{ store: "google"|"apple", purchaseToken: "..." }`
4. OpenIAP verifies the receipt with the store and returns `{ isValid: true, state: "ENTITLED" }`
5. Backend creates/updates `UserSubscription` record
6. Mobile app listens to OpenIAP SSE stream for lifecycle events (renewals, cancellations, etc.)

## API Reference

### Verify Purchase

```
POST https://kit.openiap.dev/v1/purchase/verify
Authorization: Bearer openiap-kit_<your-key>
Content-Type: application/json

{
  "store": "google",
  "purchaseToken": "purchase-token-from-app"
}
```

Response:
```json
{
  "isValid": true,
  "state": "ENTITLED"
}
```

States: `ENTITLED`, `PENDING_ACKNOWLEDGMENT`, `READY_TO_CONSUME`, `PENDING`, `CONSUMED`, `CANCELED`, `EXPIRED`, `INAUTHENTIC`, `UNKNOWN`

### SSE Stream

```
GET https://kit.openiap.dev/v1/webhooks/stream/openiap-kit_<your-key>
```

Events: `SubscriptionStarted`, `SubscriptionRenewed`, `SubscriptionExpired`, `SubscriptionCanceled`, `SubscriptionRevoked`, `PurchaseRefunded`, etc.

## Testing

- Unit tests: `spec/services/subscriptions/providers/open_iap_provider_spec.rb`
- Manual testing:
  1. Use a real `purchaseToken` from an internal test purchase
  2. Call `POST /account/billing/subscribe` with the token
  3. Verify the subscription is created with correct status

## Supported Event Types

| Event Type | Description |
|------------|-------------|
| `SubscriptionStarted` | Initial purchase or resubscribe |
| `SubscriptionRenewed` | Auto-renewal succeeded |
| `SubscriptionExpired` | Subscription expired without renewal |
| `SubscriptionCanceled` | User turned off auto-renew |
| `SubscriptionRevoked` | Access immediately revoked |
| `PurchaseRefunded` | Refund issued |
| `TestNotification` | Sandbox/test notification |

## Notes

- OpenIAP handles all verification and normalization server-side
- No service account JSON or JWT exchange needed
- When adding iOS support, just configure Apple in the OpenIAP dashboard - the same provider works for both platforms
- The `iap_product_id` column stores the product ID from either platform
- The `store` field in metadata tracks which platform ("android" or "ios")
