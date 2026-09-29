#!/usr/bin/env node

/**
 * Verify role consistency for users/employees.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json \
 *   node scripts/firestore_verify_roles.js
 */

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Missing GOOGLE_APPLICATION_CREDENTIALS env var.');
  process.exit(1);
}

admin.initializeApp();
const db = admin.firestore();

const ALLOWED_ROLES = new Set(['Owner', 'Manager', 'MPO']);

async function inspectCollection(name) {
  const snap = await db.collection(name).get();
  const missingRole = [];
  const invalidRole = [];
  let total = 0;

  for (const doc of snap.docs) {
    total += 1;
    const data = doc.data() || {};
    const role = typeof data.position === 'string' ? data.position.trim() : '';

    if (!role) {
      missingRole.push(doc.id);
      continue;
    }

    if (!ALLOWED_ROLES.has(role)) {
      invalidRole.push({ id: doc.id, role });
    }
  }

  return { name, total, missingRole, invalidRole };
}

async function run() {
  const [users, employees] = await Promise.all([
    inspectCollection('users'),
    inspectCollection('employees'),
  ]);

  const report = [users, employees];

  for (const item of report) {
    console.log(`\nCollection: ${item.name}`);
    console.log(`Total: ${item.total}`);
    console.log(`Missing position: ${item.missingRole.length}`);
    console.log(`Invalid position: ${item.invalidRole.length}`);

    if (item.missingRole.length) {
      console.log('Missing IDs:', item.missingRole.join(', '));
    }

    if (item.invalidRole.length) {
      console.log('Invalid entries:');
      for (const r of item.invalidRole) {
        console.log(`- ${r.id}: ${r.role}`);
      }
    }
  }

  const hasIssue = report.some((r) => r.missingRole.length || r.invalidRole.length);
  if (hasIssue) {
    process.exitCode = 2;
  }
}

run().catch((err) => {
  console.error('Verification failed:', err);
  process.exit(1);
});
