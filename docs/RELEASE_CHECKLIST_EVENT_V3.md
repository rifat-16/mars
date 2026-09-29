# Event V3 Release Checklist

## 1) Pre-flight
- `flutter clean`
- `flutter pub get`
- `flutter analyze`
- `flutter test`

## 2) Firebase Safety
- `firebase deploy --only firestore:rules --project mars-272dc`
- `firebase deploy --only firestore:indexes --project mars-272dc`
- `firebase firestore:indexes --project mars-272dc`

Confirm critical indexes are `READY` before rollout:
- `event_payments`: `registrationId + collectedAt`
- `event_payments`: `registrationId + participantUid + collectedAt`
- `event_registrations`: event/billing/eligibility indexes
- `event_messages`: registration and participant indexes

## 3) Finance Bootstrap (if needed)
Dry-run:
- `node scripts/event_finance_bootstrap_oauth.js --project mars-272dc`

Apply:
- `node scripts/event_finance_bootstrap_oauth.js --project mars-272dc --apply`

## 4) Build
- `flutter build apk --release`

Output:
- `build/app/outputs/flutter-apk/app-release.apk`

## 5) Smoke Test (Role-wise)
- Owner:
  - create/edit event
  - approve/reject close request
  - add/edit/delete payment
- Manager:
  - event/enrollment management
  - cannot write payments
- MPO:
  - self enrollment submit
  - own data read
  - close request submit

## 6) Event V3 Flow Smoke
- Home -> Events (New)
- Event list -> hub
- Enrollment create/submit
- Enrollment details -> Issue Medicine
- Create order (event-tagged) -> mark Delivered
- Finance recompute and due update
- Reminder/congrats SMS prompt and log

## 7) Release Notes
- Mention legacy event module removed.
- Mention Spark-compatible mode maintained (no Cloud Functions required).
- Mention payment history index warm-up may take a few minutes after first deploy.
