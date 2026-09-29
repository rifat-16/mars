#!/usr/bin/env node

/**
 * Bootstrap V2 lifecycle/finance fields for event_registrations collection.
 *
 * Usage:
 *   node scripts/event_registration_v2_bootstrap_oauth.js --project mars-272dc
 *   node scripts/event_registration_v2_bootstrap_oauth.js --project mars-272dc --apply
 */

const fs = require('fs');

function getArg(name, fallback = '') {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx >= 0 && process.argv[idx + 1]) return process.argv[idx + 1];
  return fallback;
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

async function loadAccessToken() {
  const p = `${process.env.HOME}/.config/configstore/firebase-tools.json`;
  const raw = JSON.parse(fs.readFileSync(p, 'utf8'));
  const refreshToken = raw?.tokens?.refresh_token;

  if (refreshToken) {
    const res = await fetch('https://www.googleapis.com/oauth2/v4/token', {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: new URLSearchParams({
        client_id: raw?.tokens?.client_id || '',
        client_secret: raw?.tokens?.client_secret || '',
        refresh_token: refreshToken,
        grant_type: 'refresh_token',
      }),
    });
    if (res.ok) {
      const body = await res.json();
      if (body?.access_token) {
        return body.access_token;
      }
    }
  }

  const token = raw?.tokens?.access_token;
  if (!token) throw new Error('No firebase-tools token found. Run firebase login first.');
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
  throw new Error(`Unsupported type: ${typeof value}`);
}

function decodeField(field) {
  if (!field || typeof field !== 'object') return null;
  if ('stringValue' in field) return field.stringValue;
  if ('integerValue' in field) return Number(field.integerValue);
  if ('doubleValue' in field) return Number(field.doubleValue);
  if ('booleanValue' in field) return field.booleanValue;
  if ('timestampValue' in field) return new Date(field.timestampValue);
  if ('nullValue' in field) return null;
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

async function request(url, token, options = {}) {
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

async function listCollection(project, collectionId, token, pageToken = '') {
  const qs = new URLSearchParams();
  qs.append('pageSize', '200');
  if (pageToken) qs.append('pageToken', pageToken);
  const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/${collectionId}?${qs.toString()}`;
  return request(url, token, { method: 'GET' });
}

function buildPatchUrl(docName, fieldPaths) {
  const qs = new URLSearchParams();
  for (const f of fieldPaths) {
    qs.append('updateMask.fieldPaths', f);
  }
  qs.append('currentDocument.exists', 'true');
  return `https://firestore.googleapis.com/v1/${docName}?${qs.toString()}`;
}

async function loadPaymentTotalsByRegistration(project, token) {
  const totals = new Map();
  let pageToken = '';
  do {
    const page = await listCollection(project, 'event_payments', token, pageToken);
    pageToken = page.nextPageToken || '';
    const docs = page.documents || [];
    for (const doc of docs) {
      const data = decodeDocFields(doc);
      const registrationId = String(data.registrationId || '');
      if (!registrationId) continue;
      const amount = Number(data.amount || 0);
      totals.set(registrationId, (totals.get(registrationId) || 0) + amount);
    }
  } while (pageToken);
  return totals;
}

async function main() {
  const project = getArg('project', 'mars-272dc');
  const applyMode = hasFlag('apply');
  const token = await loadAccessToken();

  const paymentTotals = await loadPaymentTotalsByRegistration(project, token);

  let scanned = 0;
  let candidates = 0;
  let updated = 0;
  let pageToken = '';

  do {
    const page = await listCollection(project, 'event_registrations', token, pageToken);
    pageToken = page.nextPageToken || '';
    const docs = page.documents || [];

    for (const doc of docs) {
      scanned += 1;
      const data = decodeDocFields(doc);
      const registrationId = doc.name.split('/').pop();
      const paymentTotal = Number(paymentTotals.get(registrationId) || 0);

      const medicineIssuedAmount = Number(
        data.medicineIssuedAmount ?? data.autoAchievedAmount ?? data.finalAchievedAmount ?? 0,
      );
      const totalPaidAmount = Number(data.totalPaidAmount ?? paymentTotal);
      const dueAmount = Math.max(medicineIssuedAmount - totalPaidAmount, 0);
      const advanceAmount = Math.max(totalPaidAmount - medicineIssuedAmount, 0);
      const eligibilityStatus = dueAmount <= 0 ? 'eligible' : 'not_eligible';

      const enrollmentStatus = data.enrollmentStatus || 'enrolled';
      const billingStatus = data.billingStatus || 'open';

      const missing =
        data.enrollmentStatus === undefined ||
        data.billingStatus === undefined ||
        data.medicineIssuedAmount === undefined ||
        data.dueAmount === undefined ||
        data.advanceAmount === undefined ||
        data.eligibilityStatus === undefined;

      if (!missing) continue;
      candidates += 1;

      if (!applyMode) {
        console.log(
          `[DRY-RUN] ${registrationId} -> enrollment=${enrollmentStatus}, billing=${billingStatus}, due=${dueAmount.toFixed(0)}`,
        );
        continue;
      }

      const now = new Date();
      const payload = {
        fields: {
          enrollmentStatus: fieldValue(enrollmentStatus),
          enrolledAt: fieldValue(data.enrolledAt || data.createdAt || now),
          enrolledByUid: fieldValue(data.enrolledByUid || data.createdByUid || 'bootstrap-script'),
          enrolledByName: fieldValue(data.enrolledByName || 'bootstrap-script'),
          billingStatus: fieldValue(billingStatus),
          medicineIssuedAmount: fieldValue(medicineIssuedAmount),
          totalPaidAmount: fieldValue(totalPaidAmount),
          dueAmount: fieldValue(dueAmount),
          advanceAmount: fieldValue(advanceAmount),
          eligibilityStatus: fieldValue(eligibilityStatus),
          financeUpdatedAt: fieldValue(now),
          financeUpdatedByUid: fieldValue('bootstrap-script'),
          updatedAt: fieldValue(now),
          updatedByUid: fieldValue('bootstrap-script'),
        },
      };

      const url = buildPatchUrl(doc.name, [
        'enrollmentStatus',
        'enrolledAt',
        'enrolledByUid',
        'enrolledByName',
        'billingStatus',
        'medicineIssuedAmount',
        'totalPaidAmount',
        'dueAmount',
        'advanceAmount',
        'eligibilityStatus',
        'financeUpdatedAt',
        'financeUpdatedByUid',
        'updatedAt',
        'updatedByUid',
      ]);

      await request(url, token, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
      updated += 1;
      console.log(`[APPLY] ${registrationId} updated`);
    }
  } while (pageToken);

  console.log('\nEvent Registration V2 Bootstrap Summary');
  console.log(`Project: ${project}`);
  console.log(`Mode: ${applyMode ? 'APPLY' : 'DRY-RUN'}`);
  console.log(`Scanned: ${scanned}`);
  console.log(`Candidates: ${candidates}`);
  console.log(`Updated: ${updated}`);
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
