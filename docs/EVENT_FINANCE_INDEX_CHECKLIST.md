# Event Finance Index Checklist

Use this checklist if Firestore shows missing-index errors in Event finance screens.

## Expected queries

1. `event_payments` by registration history
- Filter: `registrationId == <id>`
- Order: `collectedAt desc`
- Composite index: `registrationId ASC, collectedAt DESC`

2. `event_payments` by event timeline (optional for future hub trend view)
- Filter: `eventId == <id>`
- Order: `collectedAt desc`
- Composite index: `eventId ASC, collectedAt DESC`

## Setup flow

1. Open Firebase Console > Firestore Database > Indexes.
2. Create composite indexes above (if not already auto-created from error links).
3. Wait until index status becomes `Enabled`.
4. Re-test:
- Event details payment history
- Event hub finance KPIs

