# Vercel Web 배포 가이드

이 프로젝트는 Flutter Web으로 빌드되어 Vercel URL로 공유할 수 있습니다.

## 1. 레포 준비

변경사항을 GitHub/GitLab/Bitbucket 레포에 push합니다.

Vercel 빌드 설정은 `vercel.json`에 포함되어 있으므로 Vercel 화면에서 별도 빌드 명령을 직접 입력하지 않아도 됩니다.

## 2. Vercel 프로젝트 생성

1. [Vercel](https://vercel.com)에 로그인합니다.
2. `Add New...` → `Project`를 선택합니다.
3. 이 Flutter 프로젝트가 올라간 Git 레포를 import합니다.
4. Framework Preset은 `Other` 또는 자동 감지 설정을 그대로 둡니다.
5. Deploy를 실행합니다.

## 3. 배포 설정

`vercel.json` 기준 설정값은 다음과 같습니다.

- Build Command: Flutter stable SDK를 설치한 뒤 `flutter build web --release --base-href=/ --no-wasm-dry-run` 실행
- Output Directory: `build/web`
- Rewrite: 모든 경로를 `index.html`로 연결해 GoRouter 새로고침을 지원

## 4. API URL 설정

배포 전에 Vercel 환경변수에 실제 Django API 주소를 반드시 추가합니다.

- Name: `API_BASE_URL`
- Value 예시: `https://api.example.com/api/v1`

`API_BASE_URL`이 없으면 빌드는 실패합니다. 브라우저에서 API를 호출할 수 있도록 Django 서버의 CORS 허용 목록에 Vercel 배포 주소도 등록해야 합니다.

환경변수 추가 후에는 다시 Deploy 해야 적용됩니다.

## 5. 공유

배포가 끝나면 Vercel이 생성한 Production URL을 공유하면 됩니다.

예시:

```text
https://the-we-system.vercel.app
```

사용자는 브라우저에서 URL을 열거나, 모바일/PC에서 PWA로 설치해 사용할 수 있습니다.
