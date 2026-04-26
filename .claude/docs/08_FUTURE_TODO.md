# 원천청년부 앱 — 남은 TODO

## 현재 완료된 것

### Phase 1 (중보기도 MVP)
- [x] 회원 인증 (로그인/비번변경/JWT)
- [x] 중보기도 CRUD (목록/상세/작성/삭제)
- [x] 기간별 필터링 (이번 주/1개월/3개월/직접 선택)
- [x] 읽음 표시 (로컬 저장)
- [x] 댓글/반응 (🙏 토글 + 댓글 CRUD)
- [x] 다크 모드 (시스템 설정 자동)
- [x] 스플래시 스크린 (정적 + 애니메이션)
- [x] 앱 아이콘
- [x] iOS/Android 어댑티브 UI (Cupertino/Material)
- [x] HapticFeedback
- [x] Fluent UI Icons
- [x] 푸시 알림 연동 (APNs 코드 + 시뮬레이터 테스트)
- [x] 백엔드 배포 (20 Lambda, DynamoDB, API Gateway)

### Phase 2 (출결 관리)
- [x] Supabase PostgreSQL (관리형, Free Plan)
- [x] 출결 DB 스키마 (groups, group_members, attendance)
- [x] 출결 Lambda 4개 (myGroup, check, weekly, stats)
- [x] 목장 데이터 마이그레이션 (13목장, 134명, 557출석)
- [x] Flutter 출석 체크 화면 (2열 그리드 + 주차 이동)
- [x] 출석률 통계 화면 (목장별 랭킹)
- [x] 서버 KST 날짜 검증 (일요일/미래/4주이전)
- [x] 통합 테스트 47개 통과

---

## $99 없이 지금 할 수 있는 것

### 기능 개발

| # | 할 일 | 난이도 | 비고 |
|---|---|---|---|
| 1 | 목자 푸시 알림 Lambda (매주 일요일 15:00 KST) | 쉬움 | EventBridge + Lambda 코드만, 실 발송은 $99 이후 |
| 2 | 관리자 웹 대시보드 (Next.js) | 중간 | 회원 관리, 출결 현황, 기도 관리 |
| 3 | 관리자 인증 (JWT role 추가) | 쉬움 | DynamoDB Member에 role 필드 추가 |
| 4 | 신규 회원 등록 API | 쉬움 | 관리자용 CRUD |
| 5 | 송리스트 기능 (DB + Lambda + Flutter UI) | 중간 | DynamoDB or Supabase PG |
| 6 | 카카오채널 연동 (알림톡 API) | 중간 | 카카오 비즈니스 계정 필요 |
| 7 | 소셜 로그인 (Apple/Google) | 중간 | Apple은 $99 이후 |
| 8 | 오프라인 모드 (기도문 로컬 캐싱) | 중간 | Drift 패키지 재추가 |
| 9 | 공지사항 기능 | 쉬움 | DynamoDB + Flutter UI |

### UI/UX 개선

| # | 할 일 | 난이도 |
|---|---|---|
| 1 | 피그마 디자인 반영 (전체 화면) | 중간 |
| 2 | 출석 통계 차트 (fl_chart) | 쉬움 |
| 3 | 프로필/설정 화면 | 쉬움 |
| 4 | 로그아웃 기능 | 쉬움 |
| 5 | 비밀번호 재설정 (관리자 초기화) | 쉬움 |

### 코드 품질

| # | 할 일 | 난이도 |
|---|---|---|
| 1 | Flutter 위젯 테스트 추가 | 중간 |
| 2 | 기도 API 통합 테스트 추가 | 쉬움 |
| 3 | CI/CD 파이프라인 (GitHub Actions) | 중간 |

---

## $99 (Apple Developer) 가입 후 할 것

순서대로 진행:

| # | 할 일 | 비고 |
|---|---|---|
| 1 | Apple Developer Console에서 APNs Key (.p8) 발급 | Keys → New Key → APNs 체크 |
| 2 | AWS SNS Platform Application 생성 (APNs) | .p8 키 + Key ID + Team ID 등록 |
| 3 | SSM에 SNS iOS Platform ARN 등록 | `/woncheon/dev/sns-ios-arn` |
| 4 | Runner.entitlements에 aps-environment 복원 | 이미 파일 있음, 비워둔 상태 |
| 5 | 실기기 푸시 테스트 | 디바이스 토큰 등록 + 실 발송 확인 |
| 6 | TestFlight 배포 | Xcode → Archive → Upload to App Store Connect |
| 7 | 내부 테스터 그룹 추가 + 테스트 | 청년부 리더들 대상 |
| 8 | App Store 심사 제출 | 스크린샷, 설명, 개인정보처리방침 필요 |
| 9 | App Store 출시 | 심사 통과 후 |
| 10 | prod 환경 배포 | `sls deploy --stage prod` + SSM prod 파라미터 |

---

## 참고: 현재 인프라 현황

| 서비스 | 사업자 | 리소스 | 비용 |
|---|---|---|---|
| DynamoDB | AWS | woncheon-dev (PAY_PER_REQUEST), 리전 ap-northeast-2 | 무료 (200명 규모) |
| PostgreSQL | **Supabase** | pooler `aws-1-ap-northeast-2.pooler.supabase.com:5432`, project `hhnknrrcmonvcmqlkxii` | Supabase Free Plan |
| Lambda | AWS | 20개 함수 | Free Tier 범위 |
| API Gateway | AWS | REST API | Free Tier 범위 |
| SSM Parameter Store | AWS | 7개 파라미터 (PG 자격증명, JWT secret 등) | 무료 |
| S3 | AWS | Serverless 배포 아티팩트 | 거의 무료 |

> **주의**: PostgreSQL은 AWS RDS가 아니라 **Supabase** 관리형 호스팅. 호스트는 ap-northeast-2 리전이지만 사업자는 Supabase, Inc. (미국). 개인정보처리방침 Section 6에 명시됨.

## 참고: 테스트 계정

| 이름 | 역할 | 비밀번호 | 비고 |
|---|---|---|---|
| 민동익 | 목원 | 11111111 | 비번 변경 완료 |
| 김지현 | 목자 | 11111111 | 비번 변경 완료 |
| 조은주 | 목자 | 11111111 | 비번 변경 완료 |
| 조성주 | 목자 | 11111111 | 비번 변경 완료 |
| 기타 | - | woncheon2025 | 첫 로그인 시 변경 필요 |

## 배포 전 필수 복구 작업

> prod 배포 또는 실 서비스 전에 반드시 수행

- [ ] 테스트 계정 비밀번호 초기화 (민동익, 김지현, 조은주, 조성주 → `isFirstLogin: true` + 기본PW 복원)
- [ ] 테스트용 기도 게시물 삭제
- [ ] 테스트용 댓글/반응 정리
- [ ] 테스트 출석 데이터 확인 (엑셀 원본과 비교)
- [ ] `kMockMode = false` 확인 (이미 false)
- [ ] API URL을 prod 엔드포인트로 변경
- [ ] SSM prod 파라미터 등록 (JWT secrets, PG 접속정보)
- [ ] `sls deploy --stage prod`
- [ ] Runner.entitlements에 `aps-environment: production` 설정
