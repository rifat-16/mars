#!/usr/bin/env node

/**
 * Cleanup employees.password using OAuth access token from firebase-tools.
 *
 * Usage:
 *   node scripts/firestore_cleanup_employees_oauth.js --project mars-272dc
 */

const fs = require('fs');

function getArg(name, fallback = '') {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx >= 0 && process.argv[idx + 1]) return process.argv[idx + 1];
  return fallback;
}

function loadAccessToken() {
  const p = `${process.env.HOME}/.config/configstore/firebase-tools.json`;
  const raw = JSON.parse(fs.readFileSync(p, 'utf8'));
  const token = raw?.tokens?.access_token;
  if (!token) throw new Error('No firebase-tools access token found. Run firebase login first.');
  return token;
}

function decodeFirestoreDoc(doc) {
  const out = {};
  const fields = doc.fields || {};

  for (const [k, v] of Object.entries(fields)) {
    if ('stringValue' in v) out[k] = v.stringValue;
    else if ('integerValue' in v) out[k] = Number(v.integerValue || 0);
    else if ('doubleValue' in v) out[k] = Number(v.doubleValue || 0);
    else if ('booleanValue' in v) out[k] = Boolean(v.booleanValue);
    else if ('timestampValue' in v) out[k] = v.timestampValue;
    else if ('nullValue' in v) out[k] = null;
    else out[k] = v;
  }

  return out;
}

async function listEmployees(project, token) {
  const docs = [];
  let nextPageToken = '';

  do {
    const qs = new URLSearchParams({ pageSize: '300' });
    if (nextPageToken) qs.set('pageToken', nextPageToken);

    const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/employees?${qs.toString()}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!res.ok) {
      const body = await res.text();
      throw new Error(`List employees failed: ${res.status} ${body}`);
    }

    const data = await res.json();
    docs.push(...(data.documents || []));
    nextPageToken = data.nextPageToken || '';
  } while (nextPageToken);

  return docs;
}

async function removePasswordField(project, token, doc) {
  const name = doc.name; // projects/.../documents/employees/<id>
  const timestamp = new Date().toISOString();

  const url = `https://firestore.googleapis.com/v1/${name}?updateMask.fieldPaths=password&updateMask.fieldPaths=passwordRemovedAt`;

  const body = {
    fields: {
      passwordRemovedAt: { timestampValue: timestamp },
    },
  };

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Patch failed for ${name}: ${res.status} ${txt}`);
  }
}

async function main() {
  const project = getArg('project', 'mars-272dc');
  const token = loadAccessToken();

  const docs = await listEmployees(project, token);

  let scanned = 0;
  let updated = 0;
  let untouched = 0;

  for (const doc of docs) {
    scanned += 1;
    const decoded = decodeFirestoreDoc(doc);

    if (!Object.prototype.hasOwnProperty.call(decoded, 'password')) {
      untouched += 1;
      continue;
    }

    await removePasswordField(project, token, doc);
    updated += 1;
  }

  console.log('Cleanup complete');
  console.log(`Project: ${project}`);
  console.log(`Scanned: ${scanned}`);
  console.log(`Updated: ${updated}`);
  console.log(`Untouched: ${untouched}`);
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
