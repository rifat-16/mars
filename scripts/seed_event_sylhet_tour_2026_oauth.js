#!/usr/bin/env node

/**
 * Seed/update event from PDF: Mars Unani Sylhet Tour 2026.
 *
 * Usage:
 *   node scripts/seed_event_sylhet_tour_2026_oauth.js --project mars-272dc
 */

const fs = require('fs');

function getArg(name, fallback = '') {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx >= 0 && process.argv[idx + 1]) return process.argv[idx + 1];
  return fallback;
}

function loadAccessToken() {
  const path = `${process.env.HOME}/.config/configstore/firebase-tools.json`;
  const raw = JSON.parse(fs.readFileSync(path, 'utf8'));
  const token = raw?.tokens?.access_token;
  if (!token) {
    throw new Error(
      'No firebase-tools access token found. Run "firebase login" first.',
    );
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
  throw new Error(`Unsupported field type: ${typeof value}`);
}

async function seedEvent(project, token) {
  const eventId = 'sylhet_tour_2026';
  const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/events/${eventId}`;

  const now = new Date();
  const deadline = new Date('2026-04-18T23:59:59+06:00');

  const payload = {
    fields: {
      title: fieldValue('মার্শ ল্যাবরেটরীজ ইউনানী সিলেট ট্যুর'),
      slug: fieldValue('mars-unani-sylhet-tour-2026'),
      description: fieldValue(
        'ঈদের আনন্দে ভেসে যান চায়ের দেশের সবুজে। ২ দিন ৩ রাতের বিশেষ সিলেট ট্যুর প্যাকেজ।',
      ),
      targetAmount: fieldValue(20000),
      targetDeadline: fieldValue(deadline),
      qualificationStartAt: fieldValue(deadline),
      qualificationEndAt: fieldValue(deadline),
      durationLabel: fieldValue('২ দিন ৩ রাত'),
      locations: fieldValue([
        'মনোরম সাদা পাথর (ভোলাগঞ্জ)',
        'প্রকৃতি কন্যা জাফলং',
        'হযরত শাহজালাল (র.) মাজার শরীফ',
        'হযরত শাহপরান (র.) মাজার শরীফ',
        'সিলেটের দিগন্তজোড়া চা বাগান',
      ]),
      extraChargePerHead: fieldValue(0),
      status: fieldValue('active'),
      lifecycleStatus: fieldValue('enrollment_open'),
      registrationOpenAt: fieldValue(deadline),
      registrationCloseAt: fieldValue(deadline),
      eventStartAt: fieldValue(deadline),
      eventEndAt: fieldValue(deadline),
      billingMode: fieldValue('order_tag'),
      welcomeMessageTemplate: fieldValue(
        'স্বাগতম {name}! {event}-এ আপনার এনরোলমেন্ট সফল হয়েছে।',
      ),
      congratsMessageTemplate: fieldValue(
        'অভিনন্দন {name}! {event}-এর জন্য আপনি এখন Eligible।',
      ),
      createdAt: fieldValue(now),
      updatedAt: fieldValue(now),
      createdByUid: fieldValue('seed-script'),
      updatedByUid: fieldValue('seed-script'),
      createdByName: fieldValue('seed-script'),
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
