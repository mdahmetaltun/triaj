#!/usr/bin/env node

const admin = require('firebase-admin');

const projectId = process.env.FIREBASE_PROJECT_ID;
const uid = process.env.SEED_UID;

if (!projectId) {
  throw new Error('FIREBASE_PROJECT_ID is required.');
}

if (!uid) {
  throw new Error('SEED_UID is required (Firebase Auth user uid).');
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId,
});

const db = admin.firestore();
const { FieldValue } = admin.firestore;

async function main() {
  const userRef = db.collection('users').doc(uid);
  const settingsRef = userRef.collection('meta').doc('settings');
  const userRecordRef = userRef.collection('triage_records').doc();
  const legacyRef = db.collection('triage_records').doc(userRecordRef.id);

  const casePayload = {
    id: userRecordRef.id,
    uid,
    userEmail: 'demo@example.com',
    caseNo: 1,
    schema: 'Demo Schema',
    schemaKey: 'demo_schema',
    tsb: 'K1',
    mts: 'Orange',
    tsbMode: 'karar',
    seconds: 90,
    compatibilityType: 'uyumlu',
    compatibilityShort: 'Uyumlu',
    compatibilityMessage: 'Demo record seeded by CLI.',
    time: '10:30',
    discriminator: 'Demo discriminator',
    patient: {
      age: '35',
      gender: 'Erkek',
      history: ['HT'],
      arrivalTime: '10:00',
    },
    createdAt: FieldValue.serverTimestamp(),
    savedAt: FieldValue.serverTimestamp(),
  };

  const batch = db.batch();

  batch.set(
    userRef,
    {
      uid,
      email: 'demo@example.com',
      displayName: 'Demo User',
      photoUrl: null,
      providerIds: ['google.com'],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      lastLoginAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  batch.set(
    settingsRef,
    {
      uid,
      themeMode: 'light',
      evalOrder: 'sts_then_mts',
      mtsStopAtFirstYes: false,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  batch.set(userRecordRef, casePayload, { merge: true });
  batch.set(legacyRef, casePayload, { merge: true });

  await batch.commit();

  console.log('Seed completed.');
  console.log(`users/${uid}`);
  console.log(`users/${uid}/meta/settings`);
  console.log(`users/${uid}/triage_records/${userRecordRef.id}`);
  console.log(`triage_records/${userRecordRef.id}`);
}

main().catch((error) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
