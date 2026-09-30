/* Firebase Console > Project settings > Your apps > Web app의 값을 입력하세요. */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDi5zfl_Bt3r-2aDYYnVROuDkecLoVxuho',
  authDomain: 'the-we-system.firebaseapp.com',
  projectId: 'the-we-system',
  storageBucket: 'the-we-system.firebasestorage.app',
  messagingSenderId: '627473935635',
  appId: '1:627473935635:web:c3e2c4f465bed0fd5e3ee6',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  self.registration.showNotification(notification.title || '우리기술 전자결재', {
    body: notification.body || '새로운 결재 알림이 있습니다.',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const route = event.notification.data?.route || '/';
  event.waitUntil(clients.openWindow(`${self.location.origin}${route}`));
});
