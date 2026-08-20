# the-we-system

더 위 시스템 Flutter 클라이언트입니다. Django 서버와 연결하는 온라인 모드와 독립적인 UI 개발·테스트를 위한 목업 모드를 지원합니다.

## 서버 연결 실행

먼저 Django 서버를 실행합니다.

```bash
cd /Users/jeongjiyun/Documents/the_we/the-we-system-server
python3 manage.py migrate
python3 manage.py seed_demo
python3 manage.py runserver 0.0.0.0:8000
```

다른 터미널에서 Flutter Web을 실행합니다.

```bash
cd /Users/jeongjiyun/Documents/the_we/the-we-system
flutter pub get
flutter run -d chrome --web-port=8080 \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

데모 계정:

- 관리자: `edu_manager / 1234`
- 일반 사용자: `edu_teacher / 1234`
- 대표 결재자: `ceo / 1234`

Android 에뮬레이터에서는 서버 주소로 `http://10.0.2.2:8000/api/v1`을 사용합니다. 실제 기기에서는 개발 PC와 같은 네트워크에 연결하고 PC의 내부 IP를 사용해야 합니다.

## 인증과 동기화

- 로그인 토큰은 `flutter_secure_storage`에 저장됩니다.
- Dio 인터셉터가 Bearer 토큰을 자동으로 추가합니다.
- 401 응답 시 만료된 토큰을 삭제합니다.
- 로그인 및 앱 재시작 시 `/bootstrap`으로 사용자, 조직, 결재, 휴가와 관리 설정을 복원합니다.
- 기안 저장·상신·승인·반려·취소와 휴가·관리 설정 변경은 Django API에 저장됩니다.

## 목업 모드

`API_BASE_URL` 없이 실행하면 서버를 호출하지 않고 기존 목업 데이터와 로컬 액션을 사용합니다.

```bash
flutter run -d chrome
```

위젯 및 컨트롤러 테스트도 목업 모드에서 실행됩니다.

## 검증

```bash
flutter analyze
flutter test
```
