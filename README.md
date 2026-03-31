# 원천청년부 앱

원천교회 청년부 전용 Flutter 앱. 파편화된 청년부 기능(중보기도, 출결, 송리스트 등)을 단일 앱으로 통합합니다.

## 현재 개발 범위 (Phase 1)

- 회원 인증 (이름 + 비밀번호, 첫 로그인 시 비번 변경 강제)
- 중보기도 작성/조회/삭제 (익명/실명 선택)
- 기간별 필터링 (이번 주, 1개월, 3개월, 직접 선택)
- 읽음 표시
- 주간 푸시 알림 (매주 토요일 20:00 KST)

## 기술 스택

| 영역 | 기술 |
|---|---|
| Frontend | Flutter (iOS / Android) |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP | Dio (JWT 자동 갱신 인터셉터) |
| Backend | Serverless Framework v4, Node.js 22, TypeScript |
| DB | AWS DynamoDB (Single Table Design) |
| 푸시 알림 | AWS SNS → APNs |
| API | AWS API Gateway (REST) + Lambda Authorizer |
| 리전 | ap-northeast-2 (서울) |

## 프로젝트 구조

```
flutter-woncheon-youth/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── api/          # Dio client, JWT interceptor, endpoints
│   │   ├── mock/         # Mock mode for UI testing
│   │   ├── push/         # Push notification service (APNs)
│   │   ├── router/       # GoRouter configuration
│   │   ├── storage/      # Secure storage, read prayers
│   │   └── theme/        # App theme, colors
│   ├── features/
│   │   ├── auth/         # Login, change password
│   │   ├── home/         # Home screen with menu grid
│   │   ├── prayer/       # Prayer list, detail, create, filter
│   │   └── splash/       # Animated splash screen
│   └── shared/
│       ├── providers/    # Global Riverpod providers
│       └── widgets/      # Adaptive widgets (iOS/Android)
├── woncheon-backend/
│   ├── serverless.yml
│   ├── src/
│   │   ├── functions/
│   │   │   ├── auth/     # login, changePassword, refresh, authorizer, deviceToken
│   │   │   ├── prayer/   # list, create, get, delete
│   │   │   └── notification/  # sendWeekly (EventBridge cron)
│   │   ├── libs/         # dynamo, jwt, response, sns, parse-body, auth-context, env
│   │   └── types/        # Member, PrayerRequest interfaces
│   └── scripts/
│       ├── migrate-members.ts
│       └── member.csv
├── assets/
│   ├── fonts/            # Pretendard (400~700)
│   └── images/           # Logo, prayer images
└── ios/
    └── Runner/
        ├── AppDelegate.swift  # Push notification handling
        └── Runner.entitlements
```

## 시작하기

### 사전 요구사항

- Flutter SDK 3.41+
- Dart 3.11+
- Node.js 22+
- pnpm
- AWS CLI (profile: dongik2)

### Flutter 앱 실행

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Freezed, JSON Serializable)
dart run build_runner build --delete-conflicting-outputs

# 실행 (시뮬레이터)
flutter run

# 실행 (실기기)
flutter run -d <device-id>
```

### 백엔드 배포

```bash
cd woncheon-backend

# 의존성 설치
pnpm install

# 배포
pnpm sls deploy --stage dev
```

### 회원 마이그레이션

```bash
cd woncheon-backend
AWS_PROFILE=dongik2 TABLE_NAME=woncheon-dev npx tsx scripts/migrate-members.ts scripts/member.csv
```

### 푸시 알림 테스트 (시뮬레이터)

```bash
# .apns 파일을 시뮬레이터에 드래그 앤 드롭
# 또는:
xcrun simctl push booted com.woncheon.woncheonYouth test_push/prayer_notification.apns
```

## 인증 방식

- Custom Auth (이름 + 비밀번호)
- 기본 비밀번호: `woncheon2025` (첫 로그인 시 변경 필수)
- JWT Access Token (1h) + Refresh Token (30d)
- API Gateway Lambda Authorizer로 JWT 검증

## Phase 로드맵

- **Phase 1 (현재)**: 중보기도 MVP
- **Phase 2**: 출결 관리, 관리자 웹
- **Phase 3**: 카카오채널 연동, 송리스트

## API 엔드포인트

```
POST   /auth/login
POST   /auth/change-password  (JWT)
POST   /auth/refresh
POST   /auth/device-token     (JWT)

GET    /prayers               (JWT, 커서 페이지네이션, 날짜 필터)
POST   /prayers               (JWT)
GET    /prayers/{prayerId}    (JWT)
DELETE /prayers/{prayerId}    (JWT)
```
