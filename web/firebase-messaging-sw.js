importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAEChTpRx6Z_c6B_ahFXSDXCVtMLaTU68A",
  authDomain: "heart-to-heart-e3cc1.firebaseapp.com",
  projectId: "heart-to-heart-e3cc1",
  storageBucket: "heart-to-heart-e3cc1.firebasestorage.app",
  messagingSenderId: "503771997517",
  appId: "1:503771997517:web:d1269d3718251a7d380304"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title || "h2h Love Tap! 💖";
  const notificationOptions = {
    body: payload.notification.body || "Your partner is thinking of you!",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    tag: "h2h-notification",
    renotify: true,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
