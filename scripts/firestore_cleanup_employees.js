#!/usr/bin/env node

/**
 * Remove insecure plaintext password field from employees collection.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json \
 *   node scripts/firestore_cleanup_employees.js
 */

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Missing GOOGLE_APPLICATION_CREDENTIALS env var.');
  process.exit(1);
}

admin.initializeApp();
const db = admin.firestore();

async function run() {
  const snap = await db.collection('employees').get();
  if (snap.empty) {
    console.log('No employee documents found.');
    return;
  }

  let scanned = 0;
  let updated = 0;
  let untouched = 0;

  let batch = db.batch();
  let batchOps = 0;

  for (const doc of snap.docs) {
    scanned += 1;
    const data = doc.data() || {};

    if (!Object.prototype.hasOwnProperty.call(data, 'password')) {
      untouched += 1;
      continue;
    }

    batch.update(doc.ref, {
      password: admin.firestore.FieldValue.delete(),
      passwordRemovedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    batchOps += 1;
    updated += 1;

    if (batchOps >= 450) {
      await batch.commit();
      batch = db.batch();
      batchOps = 0;
    }
  }

  if (batchOps > 0) {
    await batch.commit();
  }

  console.log('Cleanup complete');
  console.log(`Scanned: ${scanned}`);
  console.log(`Updated: ${updated}`);
  console.log(`Untouched: ${untouched}`);
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Cleanup failed:', err);
    process.exit(1);
  });
