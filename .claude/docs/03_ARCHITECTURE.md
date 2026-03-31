# 원천청년부 앱 — 시스템 아키텍처

## 1. 전체 아키텍처 개요

```
┌─────────────────────────────────────────┐
│           Flutter App (Client)           │
│         iOS / Android                   │
└──────────────┬──────────────────────────┘
               │ HTTPS (REST API)
               │ JWT Bearer Token
               ▼
┌─────────────────────────────────────────┐
│         AWS API Gateway (REST)           │
│         ap-northeast-2                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│           AWS Lambda (Node.js 22.x)      │
│  ┌────────────┐  ┌─────────────────┐   │
│  │ auth       │  │ prayer          │   │
│  │ handler    │  │ handler         │   │
│  └────────────┘  └─────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │ notification handler (scheduled) │   │
│  └──────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
┌────────────┐   ┌──────────────────┐
│  DynamoDB  │   │   AWS SNS        │
│  (Single   │   │  (FCM / APNs     │
│   Table)   │   │   Platform App)  │
└────────────┘   └──────────────────┘
                          ▲
                          │ 스케줄 트리거
               ┌──────────────────┐
               │  EventBridge     │
               │  (cron: 매주 토요일 │
               │   20:00 KST)     │
               └──────────────────┘
```

---

## 2. 기술 스택 상세

### Frontend
| 항목 | 선택 | 비고 |
|---|---|---|
| Framework | Flutter (Dart) | iOS / Android 동시 지원 |
| 상태관리 | Riverpod | |
| HTTP Client | Dio | Interceptor로 JWT 자동 갱신 |
| 로컬 저장소 | flutter_secure_storage | Access/Refresh Token 저장 |
| 푸시 알림 | firebase_messaging (FCM) | iOS APNs 브릿지 포함 |

### Backend
| 항목 | 선택 | 비고 |
|---|---|---|
| IaC | Serverless Framework v4 | |
| Runtime | Node.js 22.x | |
| API | AWS API Gateway (REST) | |
| Compute | AWS Lambda | |
| DB | AWS DynamoDB | Single Table Design |
| 푸시 발송 | AWS SNS | FCM/APNs Platform Application |
| 스케줄러 | AWS EventBridge | cron 표현식 |
| 패키지 매니저 | pnpm | |
| 언어 | TypeScript | |

### 인증
| 항목 | 내용 |
|---|---|
| 방식 | Custom Auth (이름 + bcrypt 비밀번호) |
| 토큰 | JWT (Access: 1h, Refresh: 30d) |
| 저장 | flutter_secure_storage (클라이언트), Refresh Token → DynamoDB |

---

## 3. Lambda 함수 구성

```
functions/
  auth/
    login.ts          # POST /auth/login
    changePassword.ts # POST /auth/change-password
    refresh.ts        # POST /auth/refresh
    deviceToken.ts    # POST /auth/device-token
  prayer/
    list.ts           # GET  /prayers
    create.ts         # POST /prayers
    get.ts            # GET  /prayers/{prayerId}
    delete.ts         # DELETE /prayers/{prayerId}
  notification/
    sendWeekly.ts     # EventBridge cron 트리거 (스케줄)
```

---

## 4. 환경 구성 (Stage)

| Stage | 용도 |
|---|---|
| dev | 개발/테스트 |
| prod | 실 운영 |

환경 변수는 SSM Parameter Store 또는 `.env.{stage}` 파일로 관리:
```
JWT_SECRET
JWT_REFRESH_SECRET
SNS_FCM_PLATFORM_ARN
SNS_APNS_PLATFORM_ARN
DYNAMODB_TABLE_NAME
```

---

## 5. 보안 설계

- 모든 API는 HTTPS only (API Gateway 기본)
- 인증이 필요한 엔드포인트: API Gateway Lambda Authorizer로 JWT 검증
- 비밀번호: bcrypt (salt rounds: 10) 해싱 후 DynamoDB 저장
- Refresh Token: DynamoDB에 저장 (로그아웃 시 삭제로 무효화 가능)
- CORS: Flutter 앱은 네이티브이므로 CORS 불필요 (API Gateway에서 모바일 origin만 허용)

---

## 6. Serverless Framework 구조 (디렉토리)

```
woncheon-backend/
├── serverless.yml
├── package.json
├── tsconfig.json
├── src/
│   ├── functions/
│   │   ├── auth/
│   │   ├── prayer/
│   │   └── notification/
│   ├── libs/
│   │   ├── dynamo.ts       # DynamoDB 클라이언트 싱글턴
│   │   ├── jwt.ts          # JWT 발급/검증 유틸
│   │   ├── response.ts     # API 응답 헬퍼
│   │   └── sns.ts          # SNS 발송 유틸
│   └── types/
│       ├── member.ts
│       └── prayer.ts
└── tests/
```

---

## 7. Flutter 프로젝트 구조

```
woncheon-app/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # MaterialApp, 라우팅
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart     # Dio 설정, JWT 인터셉터
│   │   │   └── endpoints.dart
│   │   ├── storage/
│   │   │   └── secure_storage.dart
│   │   └── constants.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/       # login_page, change_password_page
│   │   ├── home/
│   │   │   └── presentation/       # home_page (메뉴 그리드)
│   │   └── prayer/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/       # prayer_list_page, prayer_detail_page, prayer_create_page
│   └── shared/
│       ├── widgets/
│       └── theme/
└── pubspec.yaml
```

---

## 8. 데이터 마이그레이션 계획 (Google Sheets → DynamoDB)

1. 교적부 Google Sheets에서 회원 이름 목록 export (CSV)
2. 마이그레이션 스크립트 실행 (`scripts/migrate-members.ts`)
3. 각 회원 레코드를 DynamoDB에 삽입:
   - `isFirstLogin: true`
   - `passwordHash: bcrypt(woncheon2025)`
4. 이후 Google Sheets는 원본 교적 관리용으로만 유지
5. 신규 청년부원 등록은 Lambda Admin API 또는 수동 DynamoDB 삽입으로 처리 (Phase 1)
