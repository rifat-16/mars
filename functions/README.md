# Mars Firebase Functions

## Required secrets

Set these before deploying callable SMS function:

- `BULKSMS_API_KEY`
- `BULKSMS_SENDER_ID`

Example (Firebase CLI):

```bash
firebase functions:secrets:set BULKSMS_API_KEY
firebase functions:secrets:set BULKSMS_SENDER_ID
```

## Deploy

```bash
cd functions
npm install
cd ..
firebase deploy --only functions,firestore:rules
```
