{{flutter_js}}
{{flutter_build_config}}

// 이 서비스는 항상 최신 서버 상태를 사용해야 하므로 오프라인 캐시를
// 사용하지 않는다. 이전 Flutter 배포에서 등록된 서비스 워커도 제거한다.
(async () => {
  if ('serviceWorker' in navigator) {
    const wasControlledByServiceWorker = navigator.serviceWorker.controller != null;
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(
      registrations.map((registration) => registration.unregister()),
    );

    // 이미 열린 탭은 서비스 워커를 해제해도 현재 문서가 끝날 때까지 이전
    // 앱 번들을 계속 사용할 수 있다. 한 번만 새로고침해 최신 배포본을 받는다.
    const reloadKey = 'the-we-service-worker-cleared';
    if (
      wasControlledByServiceWorker &&
      sessionStorage.getItem(reloadKey) !== 'true'
    ) {
      sessionStorage.setItem(reloadKey, 'true');
      window.location.reload();
      return;
    }
    sessionStorage.removeItem(reloadKey);
  }

  await _flutter.loader.load();
})();
