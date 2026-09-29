# Spark Mode Guide (No Cloud Functions)

This project now runs in Spark-compatible mode:

- No Cloud Functions call from app code
- Employee onboarding uses self-signup
- Order delivered flow uses client-side Firestore transaction
- SMS flow uses native SMS intent (`url_launcher`)

## Employee Onboarding

1. Employee opens `Sign Up`.
2. Select role: `Manager` or `MPO`.
3. Completes signup.
4. Owner/Manager can manage employee record from app.

## Normal User Signup

1. User opens `Sign Up` from Login screen.
2. Select role: `User`.
3. Account is created in `users` collection.
4. These accounts are not shown in Employee List.

## Delivered Flow

`OrdersRepository.markOrderDelivered()` now:
- reads matching inventory docs
- updates quantity in a Firestore transaction
- updates order status to `Delivered`

## SMS Flow

`SmsService.sendSms()` now opens device SMS app with prefilled message.
No API key, no backend secret required.
