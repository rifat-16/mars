#!/usr/bin/env node

/**
 * Verify users/employees position values using OAuth access token from firebase-tools.
 *
 * Usage:
 *   node scripts/firestore_verify_roles_oauth.js --project mars-272dc
 */

const fs = require('fs');

const ALLOWED_ROLES = new Set(['Owner', 'Manager', 'MPO']);

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

function decodeFields(fields) {
  const out = {};
  for (const [k, v] of Object.entries(fields || {})) {
    if ('stringValue' in v) out[k] = v.stringValue;
    else out[k] = null;
  }
  return out;
}

async function listCollection(project, collection) {
  const token = loadAccessToken();
  const docs = [];
  let nextPageToken = '';

  do {
    const qs = new URLSearchParams({ pageSize: '300' });
    if (nextPageToken) qs.set('pageToken', nextPageToken);

    const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/${collection}?${qs.toString()}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!res.ok) {
      const body = await res.text();
      throw new Error(`List ${collection} failed: ${res.status} ${body}`);
    }

    const data = await res.json();
    docs.push(...(data.documents || []));
    nextPageToken = data.nextPageToken || '';
  } while (nextPageToken);

  return docs;
}

function docIdFromName(name) {
  const parts = name.split('/');
  return parts[parts.length - 1] || name;
}

async function inspect(project, collection) {
  const docs = await listCollection(project, collection);
  const missingRole = [];
  const invalidRole = [];

  for (const doc of docs) {
    const id = docIdFromName(doc.name || '');
    const data = decodeFields(doc.fields || {});
    const role = typeof data.position === 'string' ? data.position.trim() : '';

    if (!role) {
      missingRole.push(id);
      continue;
    }

    if (!ALLOWED_ROLES.has(role)) {
      invalidRole.push({ id, role });
    }
  }

  return { collection, total: docs.length, missingRole, invalidRole };
}

async function main() {
  const project = getArg('project', 'mars-272dc');

  const reports = await Promise.all([
    inspect(project, 'users'),
    inspect(project, 'employees'),
  ]);

  for (const r of reports) {
    console.log(`\nCollection: ${r.collection}`);
    console.log(`Total: ${r.total}`);
    console.log(`Missing position: ${r.missingRole.length}`);
    console.log(`Invalid position: ${r.invalidRole.length}`);

    if (r.missingRole.length) {
      console.log(`Missing IDs: ${r.missingRole.join(', ')}`);
    }

    if (r.invalidRole.length) {
      console.log('Invalid entries:');
      for (const item of r.invalidRole) {
        console.log(`- ${item.id}: ${item.role}`);
      }
    }
  }

  const hasIssue = reports.some((r) => r.missingRole.length || r.invalidRole.length);
  if (hasIssue) process.exitCode = 2;
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
