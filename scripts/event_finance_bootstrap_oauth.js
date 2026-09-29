#!/usr/bin/env node

/**
 * Bootstrap finance snapshot fields for existing event registrations.
 * Spark-compatible OAuth script using firebase-tools access token.
 *
 * Usage:
 *   node scripts/event_finance_bootstrap_oauth.js --project mars-272dc
 *   node scripts/event_finance_bootstrap_oauth.js --project mars-272dc --apply
 */

const fs = require('fs');

const DEFAULT_PROJECT = 'mars-272dc';
const BOOTSTRAP_UID = 'bootstrap-script';
const TARGET_FIELDS = [
  'financialBaseAmount',
  'totalPaidAmount',
  'dueAmount',
  'advanceAmount',
  'financeUpdatedAt',
  'financeUpdatedByUid',
];

function getArg(name, fallback = '') {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx >= 0 && process.argv[idx + 1]) return process.argv[idx + 1];
  return fallback;
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

function loadAccessToken() {
  const path = `${process.env.HOME}/.config/configstore/firebase-tools.json`;
  const raw = JSON.parse(fs.readFileSync(path, 'utf8'));
  const token = raw?.tokens?.access_token;
  if (!token) {
    throw new Error('No firebase-tools access token found. Run "firebase login" first.');
  }
  return token;
}

function fieldValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map((v) => fieldValue(v)),
      },
    };
  }
  if (typeof value === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      fields[k] = fieldValue(v);
    }
    return { mapValue: { fields } };
  }
  throw new Error(`Unsupported field type: ${typeof value}`);
}

function decodeField(field) {
  if (!field || typeof field !== 'object') return null;
  if ('stringValue' in field) return field.stringValue;
  if ('integerValue' in field) return Number(field.integerValue);
  if ('doubleValue' in field) return Number(field.doubleValue);
  if ('booleanValue' in field) return field.booleanValue;
  if ('timestampValue' in field) return new Date(field.timestampValue);
  if ('nullValue' in field) return null;
  if ('arrayValue' in field) {
    const values = field.arrayValue?.values || [];
    return values.map((v) => decodeField(v));
  }
  if ('mapValue' in field) {
    const mapFields = field.mapValue?.fields || {};
    const out = {};
    for (const [k, v] of Object.entries(mapFields)) {
      out[k] = decodeField(v);
    }
    return out;
  }
  return null;
}

function decodeDocFields(doc) {
  const fields = doc?.fields || {};
  const out = {};
  for (const [k, v] of Object.entries(fields)) {
    out[k] = decodeField(v);
  }
  return out;
}

async function firestoreRequest(url, token, options = {}) {
  const res = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${res.status} ${text}`);
  }

  return res.json();
}

function buildDocUrl(project, path) {
  return `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/${path}`;
}

function buildPatchUrl(docName, fieldPaths) {
  const params = new URLSearchParams();
  for (const key of fieldPaths) {
    params.append('updateMask.fieldPaths', key);
  }
  params.append('currentDocument.exists', 'true');
  return `https://firestore.googleapis.com/v1/${docName}?${params.toString()}`;
}

async function fetchEventTargetAmount(project, token, eventId, cache) {
  if (!eventId) return 0;
  if (cache.has(eventId)) return cache.get(eventId);

  const url = buildDocUrl(project, `events/${eventId}`);
  try {
    const doc = await firestoreRequest(url, token, { method: 'GET' });
    const data = decodeDocFields(doc);
    const targetAmount = Number(data.targetAmount) || 0;
    cache.set(eventId, targetAmount);
    return targetAmount;
  } catch (error) {
    const message = String(error.message || error);
    if (message.startsWith('404 ')) {
      cache.set(eventId, 0);
      return 0;
    }
    throw error;
  }
}

async function listRegistrations(project, token, pageToken, pageSize) {
  const params = new URLSearchParams();
  params.append('pageSize', String(pageSize));
  if (pageToken) {
    params.append('pageToken', pageToken);
  }

  const url = `${buildDocUrl(project, 'event_registrations')}?${params.toString()}`;
  return firestoreRequest(url, token, { method: 'GET' });
}

function shouldBootstrap(data) {
  return TARGET_FIELDS.some((field) => data[field] === undefined);
}

function makePatchPayload(baseAmount, now) {
  const dueAmount = baseAmount > 0 ? baseAmount : 0;
  return {
    fields: {
      financialBaseAmount: fieldValue(baseAmount),
      totalPaidAmount: fieldValue(0),
      dueAmount: fieldValue(dueAmount),
      advanceAmount: fieldValue(0),
      financeUpdatedAt: fieldValue(now),
      financeUpdatedByUid: fieldValue(BOOTSTRAP_UID),
      updatedAt: fieldValue(now),
      updatedByUid: fieldValue(BOOTSTRAP_UID),
    },
  };
}

async function bootstrap(project, token, applyMode, pageSize) {
  const eventTargetCache = new Map();
  let pageToken = '';
  let scanned = 0;
  let candidates = 0;
  let updated = 0;
  let errors = 0;

  do {
    const page = await listRegistrations(project, token, pageToken, pageSize);
    const docs = page.documents || [];
    pageToken = page.nextPageToken || '';

    for (const doc of docs) {
      scanned += 1;
      const data = decodeDocFields(doc);
      if (!shouldBootstrap(data)) {
        continue;
      }

      candidates += 1;

      const eventId = String(data.eventId || '');
      const targetAmount = await fetchEventTargetAmount(
        project,
        token,
        eventId,
        eventTargetCache,
      );
      const baseAmount = targetAmount > 0 ? targetAmount : 0;
      const now = new Date();

      if (!applyMode) {
        console.log(
          `[DRY-RUN] ${doc.name.split('/').pop()} -> base=${baseAmount.toFixed(0)} due=${baseAmount.toFixed(0)}`,
        );
        continue;
      }

      try {
        const url = buildPatchUrl(doc.name, [
          ...TARGET_FIELDS,
          'updatedAt',
          'updatedByUid',
        ]);
        const payload = makePatchPayload(baseAmount, now);
        await firestoreRequest(url, token, {
          method: 'PATCH',
          body: JSON.stringify(payload),
        });
        updated += 1;
        console.log(`[APPLY] ${doc.name.split('/').pop()} updated`);
      } catch (error) {
        errors += 1;
        console.error(
          `[ERROR] ${doc.name.split('/').pop()} -> ${String(error.message || error)}`,
        );
      }
    }
  } while (pageToken);

  console.log('\nBootstrap Summary');
  console.log(`Project: ${project}`);
  console.log(`Mode: ${applyMode ? 'APPLY' : 'DRY-RUN'}`);
  console.log(`Scanned registrations: ${scanned}`);
  console.log(`Candidates (missing finance fields): ${candidates}`);
  console.log(`Updated: ${updated}`);
  console.log(`Errors: ${errors}`);
}

async function main() {
  const project = getArg('project', DEFAULT_PROJECT);
  const pageSize = Number(getArg('pageSize', '200')) || 200;
  const applyMode = hasFlag('apply');
  const token = loadAccessToken();

  await bootstrap(project, token, applyMode, pageSize);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
