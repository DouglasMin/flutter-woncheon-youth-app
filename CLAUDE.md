# 원천청년부 앱 — Project Context

## 프로젝트 개요

원천교회 청년부 전용 Flutter 앱. 파편화된 청년부 기능(출결, 송리스트, 중보기도 등)을 단일 앱으로 통합하는 것이 목표.

**현재 개발 범위 (Phase 1)**: 중보기도 작성/조회/푸시 알림 MVP

---

## 기술 스택

| 영역 | 기술 |
|---|---|
| Frontend | Flutter (iOS / Android) |
| Backend IaC | Serverless Framework v4 |
| Runtime | Node.js 22.x, TypeScript |
| API | AWS API Gateway (REST) + Lambda Authorizer (JWT) |
| DB | AWS DynamoDB (Single Table Design) |
| 푸시 알림 | AWS SNS → FCM / APNs |
| 스케줄러 | AWS EventBridge |
| 패키지 매니저 | pnpm (npm 사용 금지) |
| 리전 | ap-northeast-2 |

---

## 컨벤션 (반드시 준수)

- stage 변수: `${sls:stage}` (❌ `${self:provider.stage}` 사용 금지)
- 패키지 설치: `pnpm add` (❌ `npm install` 사용 금지)
- Node.js 버전: 22.x
- 환경 변수: SSM Parameter Store (`/woncheon/{stage}/...`)
- DynamoDB 테이블명: `woncheon-${sls:stage}`
- ID 생성: `ulid`
- 비밀번호 해싱: `bcryptjs` (salt rounds: 10)

---

## 인증 방식

- Custom Auth (이름 + 비밀번호)
- JWT Access Token (1h) + Refresh Token (30d)
- API Gateway Lambda Authorizer로 JWT 검증
- Lambda 내부에서 `event.requestContext.authorizer.memberId`로 사용자 식별

---

## DynamoDB Key 패턴

| 엔티티 | PK | SK |
|---|---|---|
| Member | `MEMBER#{memberId}` | `#META` |
| RefreshToken | `MEMBER#{memberId}` | `TOKEN#{token}` |
| PrayerRequest | `PRAYER#{prayerId}` | `#META` |
| DeviceToken | `MEMBER#{memberId}` | `DEVICE#{platform}#{token}` |

GSI 구성:
- GSI1: 이름으로 회원 조회 (`NAME#{name}`)
- GSI2: 중보기도 전체 목록 최신순 (`PRAYER_LIST`)
- GSI3: 전체 디바이스 토큰 조회 (`ALL_DEVICES`)

---

## API 엔드포인트 요약

```
POST   /auth/login
POST   /auth/change-password  (JWT 필요)
POST   /auth/refresh
POST   /auth/device-token     (JWT 필요)

GET    /prayers               (JWT 필요, 커서 페이지네이션)
POST   /prayers               (JWT 필요)
GET    /prayers/{prayerId}    (JWT 필요)
DELETE /prayers/{prayerId}    (JWT 필요)
```

---

## Lambda 함수 구조

```
src/functions/
  auth/
    authorizer.ts     # JWT Lambda Authorizer
    login.ts
    changePassword.ts
    refresh.ts
    deviceToken.ts
  prayer/
    list.ts
    create.ts
    get.ts
    delete.ts
  notification/
    sendWeekly.ts     # EventBridge cron: 매주 토요일 KST 20:00
```

---

## 상세 문서 참조

| 문서 | 경로 |
|---|---|
| PRD (기능 요구사항) | `.claude/docs/01_PRD.md` |
| User Flow | `.claude/docs/02_USER_FLOW.md` |
| 시스템 아키텍처 | `.claude/docs/03_ARCHITECTURE.md` |
| DynamoDB 스키마 | `.claude/docs/04_DB_SCHEMA.md` |
| API 명세서 | `.claude/docs/05_API_SPEC.md` |
| serverless.yml 및 세팅 가이드 | `.claude/docs/06_SETUP_AND_SERVERLESS.md` |
| iOS 배포 자동화 | `.claude/docs/07_IOS_DEPLOY_AUTOMATION.md` |

---

## Phase 로드맵

- **Phase 1 (현재)**: 중보기도 MVP
- **Phase 2**: 출결 관리, 관리자 웹
- **Phase 3**: 카카오채널 연동, 송리스트
