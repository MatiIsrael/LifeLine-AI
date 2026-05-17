# Scalability Explanation

## Horizontal API tier
- **Express** stateless services behind load balancer
- WebSocket: sticky sessions or Redis pub/sub fan-out for multi-instance broadcast
- Auto-scale on CPU and active WebSocket connections

## Data layer
- **Firestore** regional databases (EU, US, africa-south1) for data residency
- Partition `emergencies` by `regionId` + composite indexes on `status`, `triggeredAt`
- Cold storage: BigQuery export for analytics and model training

## Real-time at national scale
| Volume | Approach |
|--------|----------|
| <10k concurrent WS | Single hub + vertical scale |
| 10k–500k | Redis Pub/Sub + dedicated WS workers |
| 500k+ | Regional hubs; cross-region only for federal incidents |

## Mobile scale
- FCM topic per region for broadcast alerts
- Offline sync: idempotent `clientEventId` (already in sync API)
- CDN for static assets; feature flags via Remote Config

## AI / geospatial
- Precomputed heatmap tiles per city (nightly batch)
- Real-time scoring from in-memory grid cache (Redis)
- Model versioning for danger scores without app updates

## Cost controls
- Demo mode and seed data for dev
- Rate limits on public safety APIs
- Tiered retention: 90-day hot incidents, archive after

## Pilot → nation path
1. **City pilot** — single Firestore project, one dashboard tenant
2. **Region** — shard by `regionId`, shared identity (Firebase Auth)
3. **Nation** — multi-tenant dashboard, government SSO, dedicated WS region
