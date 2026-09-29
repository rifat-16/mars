const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp();
const db = admin.firestore();

async function getCallerProfile(uid) {
  const usersDoc = await db.collection('users').doc(uid).get();
  if (usersDoc.exists) {
    return usersDoc.data() || {};
  }

  const employeesDoc = await db.collection('employees').doc(uid).get();
  if (employeesDoc.exists) {
    return employeesDoc.data() || {};
  }

  return {};
}

function ensureOwnerOrManager(profile) {
  const role = profile.position;
  if (role !== 'Owner' && role !== 'Manager') {
    throw new functions.https.HttpsError('permission-denied', 'Owner or Manager access required.');
  }
}

exports.sendTransactionalSms = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const profile = await getCallerProfile(context.auth.uid);
  ensureOwnerOrManager(profile);

  const number = typeof data.number === 'string' ? data.number.trim() : '';
  const message = typeof data.message === 'string' ? data.message.trim() : '';

  if (!number || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'number and message are required.');
  }

  const apiKey = process.env.BULKSMS_API_KEY;
  const senderId = process.env.BULKSMS_SENDER_ID;

  if (!apiKey || !senderId) {
    throw new functions.https.HttpsError('failed-precondition', 'SMS secrets are not configured.');
  }

  const url = `http://bulksmsbd.net/api/smsapi?api_key=${encodeURIComponent(apiKey)}&type=text&number=${encodeURIComponent(number)}&senderid=${encodeURIComponent(senderId)}&message=${encodeURIComponent(message)}`;

  const response = await fetch(url);
  const body = await response.text();

  if (!response.ok) {
    throw new functions.https.HttpsError('internal', `SMS provider request failed: ${body}`);
  }

  return { ok: true, providerResponse: body };
});

exports.createEmployeeAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const profile = await getCallerProfile(context.auth.uid);
  ensureOwnerOrManager(profile);

  const name = typeof data.name === 'string' ? data.name.trim() : '';
  const position = typeof data.position === 'string' ? data.position.trim() : '';
  const email = typeof data.email === 'string' ? data.email.trim() : '';
  const phone = typeof data.phone === 'string' ? data.phone.trim() : '';
  const password = typeof data.password === 'string' ? data.password : '';
  const location = typeof data.location === 'string' ? data.location.trim() : '';

  if (!name || !position || !email || !phone || !password || !location) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required employee fields.');
  }

  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName: name,
  });

  await db.collection('employees').doc(userRecord.uid).set({
    name,
    position,
    email,
    phone,
    location,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: context.auth.uid,
  });

  return { ok: true, uid: userRecord.uid };
});

exports.markOrderDelivered = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const profile = await getCallerProfile(context.auth.uid);
  ensureOwnerOrManager(profile);

  const orderId = typeof data.orderId === 'string' ? data.orderId.trim() : '';
  const items = Array.isArray(data.items) ? data.items : [];

  if (!orderId) {
    throw new functions.https.HttpsError('invalid-argument', 'orderId is required.');
  }

  await db.runTransaction(async (tx) => {
    const orderRef = db.collection('orders').doc(orderId);
    const orderSnap = await tx.get(orderRef);

    if (!orderSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Order not found.');
    }

    for (const raw of items) {
      const productName = typeof raw.product === 'string' ? raw.product.trim() : '';
      const quantity = Number(raw.quantity || 0);

      if (!productName || quantity <= 0) {
        continue;
      }

      const inventoryQuery = db
        .collection('inventory')
        .where('productName', '==', productName)
        .limit(1);

      const inventorySnap = await tx.get(inventoryQuery);
      if (inventorySnap.empty) {
        continue;
      }

      const itemDoc = inventorySnap.docs[0];
      const currentQuantity = Number(itemDoc.data().quantity || 0);
      const nextQuantity = Math.max(0, currentQuantity - quantity);

      tx.update(itemDoc.ref, {
        quantity: nextQuantity,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    tx.update(orderRef, {
      status: 'Delivered',
      deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
      deliveredBy: context.auth.uid,
    });
  });

  return { ok: true };
});
