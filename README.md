# the-we-system

더우리기술 전자결재 시스템 Flutter 클라이언트입니다. 모든 업무 데이터는 Django 서버에서 조회하고 저장합니다.

## 서버 연결 실행

먼저 Django 서버를 실행합니다.

```bash
cd /Users/jeongjiyun/Documents/the_we/the-we-system-server
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:8000
```

빈 데이터베이스에서 관리자 기능이 필요하면 서버 실행 전에 실제 관리자 계정을 생성합니다.

```bash
python3 manage.py createsuperuser
```

다른 터미널에서 Flutter Web을 실행합니다.

```bash
cd /Users/jeongjiyun/Documents/the_we/the-we-system
flutter pub get
flutter run -d chrome --web-port=8080
```

로컬 웹과 데스크톱의 기본 서버 주소는 `http://127.0.0.1:8000/api/v1`입니다. Android 에뮬레이터에서는 `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`을 지정합니다. 실제 기기에서는 개발 PC와 같은 네트워크에 연결하고 PC의 내부 IP를 사용해야 합니다.

## 인증과 동기화

- 로그인 토큰은 `flutter_secure_storage`에 저장됩니다.
- Dio 인터셉터가 Bearer 토큰을 자동으로 추가합니다.
- 401 응답 시 만료된 토큰을 삭제합니다.
- 로그인 및 앱 재시작 시 `/bootstrap`으로 사용자, 조직, 결재, 휴가와 관리 설정을 복원합니다.
- 기안 저장·상신·승인·반려·취소와 휴가·관리 설정 변경은 Django API에 저장됩니다.

## 서버 주소 변경

로컬 기본 주소가 아닌 서버를 사용할 때는 실행 또는 빌드 시 `API_BASE_URL`을 지정합니다.

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://your-api.example.com/api/v1
```

## 검증

```bash
flutter analyze
flutter test
```
