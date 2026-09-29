# Security Checklist (Spark Mode)

## 1) Remove plaintext employee passwords

If you have service account credential:

```bash
GOOGLE_APPLICATION_CREDENTIALS=/ABS/PATH/serviceAccount.json \
node scripts/firestore_cleanup_employees.js
```

If you are logged in with Firebase CLI only:

```bash
node scripts/firestore_cleanup_employees_oauth.js --project mars-272dc
```

## 2) Verify role consistency

```bash
node scripts/firestore_verify_roles_oauth.js --project mars-272dc
```

Allowed roles:
- `Owner`
- `Manager`
- `MPO`

## 3) Deploy Firestore rules only

```bash
firebase deploy --only firestore:rules --project mars-272dc
```

## 4) Smoke checks

1. Login with Owner account.
2. Employee self-signup with Manager/MPO.
3. Create order and mark delivered.
4. Confirm inventory quantity decreases.
5. SMS screen opens native message app.
