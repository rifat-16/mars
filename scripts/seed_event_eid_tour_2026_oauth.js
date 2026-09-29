#!/usr/bin/env node

/**
 * Seed or update Eid Tour 2026 event (Spark-compatible) using firebase-tools OAuth token.
 *
 * Usage:
 *   node scripts/seed_event_eid_tour_2026_oauth.js --project mars-272dc
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
  throw new Error(`Unsupported field type: ${typeof value}`);
}

async function seedEvent(project, token) {
  const eventId = 'eid_tour_2026';
  const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/events/${eventId}`;

  const now = new Date();
  const payload = {
    fields: {
      title: fieldValue('ঈদ ট্যুর ২০২৬'),
      slug: fieldValue('eid-tour-2026'),
      description: fieldValue('২ দিন ৩ রাত সিলেট ট্যুর প্যাকেজ। লক্ষ্য অর্জনকারীদের জন্য বিশেষ আয়োজন।'),
      targetAmount: fieldValue(20000),
      targetDeadline: fieldValue(new Date('2026-04-18T23:59:59.000Z')),
      qualificationStartAt: fieldValue(new Date('2026-01-01T00:00:00.000Z')),
      qualificationEndAt: fieldValue(new Date('2026-04-18T23:59:59.000Z')),
      durationLabel: fieldValue('2 দিন 3 রাত'),
      locations: fieldValue([
        'সাদা পাথর (ভোলাগঞ্জ)',
        'জাফলং',
        'শাহজালাল (র.) মাজার',
        'শাহপরান (র.) মাজার',
        'চা বাগান',
      ]),
      extraChargePerHead: fieldValue(2000),
      status: fieldValue('active'),
      createdAt: fieldValue(now),
      updatedAt: fieldValue(now),
      createdByUid: fieldValue('seed-script'),
      updatedByUid: fieldValue('seed-script'),
    },
  };

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Seed failed: ${res.status} ${text}`);
  }

  const data = await res.json();
  console.log('Seeded event document:');
  console.log(data.name || eventId);
}

async function main() {
  const project = getArg('project', 'mars-272dc');
  const token = loadAccessToken();
  await seedEvent(project, token);
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
