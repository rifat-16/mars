# Event V2 Index Checklist

Create these composite indexes if Firestore prompts missing index errors.

1. `events`
- `lifecycleStatus ASC`
- `updatedAt DESC`

2. `event_registrations`
- `eventId ASC`
- `updatedAt DESC`

3. `event_registrations`
- `eventId ASC`
- `billingStatus ASC`
- `updatedAt DESC`

4. `event_registrations`
- `eventId ASC`
- `eligibilityStatus ASC`
- `updatedAt DESC`

5. `event_payments`
- `registrationId ASC`
- `collectedAt DESC`

6. `orders`
- `eventRegistrationId ASC`
- `createdAt DESC`

7. `event_messages`
- `registrationId ASC`
- `createdAt DESC`
