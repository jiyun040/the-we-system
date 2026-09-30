{{flutter_js}}
{{flutter_build_config}}

// FCM 웹 푸시 서비스 워커(firebase-messaging-sw.js)는 유지해야 한다.
// Flutter 자체 캐시 서비스 워커만 정리한다.
(async () => {
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(
      registrations
        .filter((registration) =>
          registration.active?.scriptURL.includes('flutter_service_worker.js'),
        )
        .map((registration) => registration.unregister()),
    );
  }

  await _flutter.loader.load();
})();
