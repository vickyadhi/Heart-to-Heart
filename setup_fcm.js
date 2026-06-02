#!/usr/bin/env node
/**
 * h2h FCM Setup Script
 * 
 * This uploads your Firebase Service Account JSON to Firestore's config/fcm document.
 * The Flutter app reads this to send push notifications directly (no Cloud Functions needed).
 * 
 * Usage:
 *   node setup_fcm.js path/to/your-service-account.json
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccountPath = process.argv[2];

if (!serviceAccountPath) {
  console.error('\n❌ Usage: node setup_fcm.js path/to/your-service-account.json\n');
  console.log('📋 How to get your service account JSON:');
  console.log('   1. Go to https://console.firebase.google.com/project/heart-to-heart-e3cc1/settings/serviceaccounts/adminsdk');
  console.log('   2. Click "Generate new private key"');
  console.log('   3. Save the downloaded JSON file');
  console.log('   4. Run: node setup_fcm.js ~/Downloads/heart-to-heart-e3cc1-firebase-adminsdk-*.json\n');
  process.exit(1);
}

const fullPath = path.resolve(serviceAccountPath);

if (!fs.existsSync(fullPath)) {
  console.error(`❌ File not found: ${fullPath}`);
  process.exit(1);
}

const serviceAccountJson = fs.readFileSync(fullPath, 'utf8');

// Validate it's a proper service account JSON
let parsed;
try {
  parsed = JSON.parse(serviceAccountJson);
  if (!parsed.type || parsed.type !== 'service_account') {
    throw new Error('Not a service account JSON');
  }
} catch (e) {
  console.error('❌ Invalid service account JSON:', e.message);
  process.exit(1);
}

console.log(`\n✅ Service account found for project: ${parsed.project_id}`);
console.log(`   Client email: ${parsed.client_email}`);

// Initialize with this service account
const serviceAccount = JSON.parse(serviceAccountJson);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'heart-to-heart-e3cc1',
});

const db = admin.firestore();

async function uploadServiceAccount() {
  try {
    console.log('\n📤 Uploading service account to Firestore config/fcm...');
    
    await db.collection('config').doc('fcm').set({
      serviceAccount: serviceAccountJson,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      projectId: parsed.project_id,
      clientEmail: parsed.client_email,
    });
    
    console.log('✅ Service account uploaded successfully to Firestore!');
    console.log('✅ Push notifications should now work in the h2h app.');
    console.log('\n⚠️  SECURITY NOTE: Make sure Firestore Security Rules protect config/fcm');
    console.log('   Only authenticated users should be able to READ it (app needs to read it).');
    console.log('   NO users should be able to WRITE it (only this admin script).\n');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to upload to Firestore:', error);
    process.exit(1);
  }
}

uploadServiceAccount();
