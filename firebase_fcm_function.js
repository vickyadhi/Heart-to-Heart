/**
 * Firebase Cloud Function for background / lock-screen push notifications.
 * Deploy this to your Firebase project to automatically send real-time
 * vibrations and push notifications when your partner taps!
 * 
 * To deploy:
 * 1. Initialize Cloud Functions in your project: firebase init functions
 * 2. Paste this code inside functions/index.js
 * 3. Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendLoveNotification = functions.firestore
  .document('conversations/{convoId}/events/{eventId}')
  .onCreate(async (snapshot, context) => {
    const eventData = snapshot.data();
    if (!eventData) return null;

    const senderId = eventData.senderId;
    const receiverId = eventData.receiverId;
    const eventType = eventData.type;
    const eventMessage = eventData.message;

    try {
      // 1. Fetch the receiver user profile to get their FCM Device Token
      const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) {
        console.log(`User ${receiverId} profile not found.`);
        return null;
      }

      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.fcmToken;

      if (!fcmToken) {
        console.log(`User ${receiverId} does not have an registered FCM Token.`);
        return null;
      }

      // 2. Fetch the sender's display name to personalize the notification
      const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
      const senderName = senderDoc.exists ? senderDoc.data().displayName : 'Your partner';

      // 3. Construct the push payload matching h2h premium alerts
      let emojiIcon = '❤️';
      if (eventType === 'miss_you') emojiIcon = '🥺';
      if (eventType === 'sad') emojiIcon = '😢';
      if (eventType === 'excited') emojiIcon = '🤩';
      if (eventType === 'thinking') emojiIcon = '💭';

      const payload = {
        token: fcmToken,
        notification: {
          title: senderName,
          body: `${eventMessage} ${emojiIcon}`,
        },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          senderId: senderId,
          type: eventType,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            vibrateTimingsMillis: [0, 250, 250, 250], // Premium physical vibration pattern!
            channelId: 'high_importance_channel',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              critical: true, // Bypass silent switch for premium tactile feelings if authorized!
            },
          },
        },
      };

      // 4. Send message to the device via FCM
      const response = await admin.messaging().send(payload);
      console.log('💚 [h2h] Push notification delivered successfully:', response);
      return response;
    } catch (error) {
      console.error('🧡 [h2h] Push notification delivery failed:', error);
      return null;
    }
  });
