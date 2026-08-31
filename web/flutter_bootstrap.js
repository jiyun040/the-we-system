{{flutter_js}}
{{flutter_build_config}}

// 이 서비스는 항상 최신 서버 상태를 사용해야 하므로 오프라인 캐시를
// 사용하지 않는다. 이전 Flutter 배포에서 등록된 서비스 워커도 제거한다.
(async () => {
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(
      registrations.map((registration) => registration.unregister()),
    );
  }

  await _flutter.loader.load();
})();
