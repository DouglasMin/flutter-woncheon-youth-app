# 원천청년부 앱 — 남은 TODO

> 마지막 갱신: 2026-05-21
> 현황: v1.0.4+5 비공개 테스트 트랙 배포 중. 정식 출시 결정 대기.

---

## 완료된 것

### Phase 1 (중보기도 MVP) — ✅ 완료
- [x] 회원 인증 (로그인/비번변경/JWT)
- [x] 중보기도 CRUD (목록/상세/작성/삭제)
- [x] 기간별 필터링 (이번 주/1개월/3개월/직접 선택)
- [x] 읽음 표시 (로컬 저장)
- [x] 댓글/반응 (🙏 토글 + 댓글 CRUD)
- [x] 다크 모드 + 스플래시 + 앱 아이콘
- [x] iOS/Android 어댑티브 UI (Cupertino/Material)
- [x] HapticFeedback + Fluent UI Icons
- [x] 푸시 알림: APNs (iOS) + FCM (Android), heads-up popup
- [x] 백엔드 배포 (20+ Lambda, DynamoDB, API Gateway)

### Phase 2 (출결 관리) — ✅ 완료
- [x] Supabase PostgreSQL (관리형, Free Plan, 단일 인스턴스)
- [x] 출결 DB 스키마 (groups, group_members, attendance)
- [x] 출결 Lambda 4개 (myGroup, check, weekly, stats)
- [x] 목장 데이터 마이그레이션 + 5/21 sheet→DB 재동기화 (시트 SoT 정책)
- [x] Flutter 출석 체크 + 통계 화면
- [x] 서버 KST 날짜 검증 (일요일/미래/4주이전)

### App Store / Play Store 심사 대비 — ✅ 완료
- [x] 사용자 차단 기능 (Guideline 1.2) — 백엔드 + Flutter UI + admin 화면
- [x] 신고 기능 + admin 검토 페이지 + DynamoDB GSI4
- [x] 24시간 검토 SOP 문서화
- [x] 앱 내 문의 (이메일·전화)
- [x] 계정 삭제 (Guideline 5.1.1(v))
- [x] Privacy Policy + Apple 심사 노트
- [x] Play Store 메타데이터

### 운영 인프라 — ✅ 완료
- [x] admin Next.js 패널 7페이지 (대시보드, 회원, 출결, 기도, 신고, 목장, 가입요청)
- [x] 비공개 테스트 트랙 배포 (Play Console + TestFlight)
- [x] 브랜치 분리: main(prod) + dev(작업)
- [x] main 브랜치 보호 (직접 push 차단)

---

## 정식 출시 직전 1회 작업

> 청년부 공지 직전에 수행. **사용자가 "활성 테스터 = 실제 사용자"로 갈 거라 데이터 정리 작업은 스킵**.

- [ ] dev → main 머지 (정식 출시용 빌드 커밋)
- [ ] main에서 빌드 (`flutter build appbundle --release`, `flutter build ipa --release`)
- [ ] App Store Connect 정식 트랙 제출
- [ ] Play Console 프로덕션 트랙 제출
- [ ] 청년부에 공지 (가입 절차 + 앱 사용법 안내)

---

## 출시 후 운영 (시간 되는 대로)

### Admin 보강 (별도 배포, 앱 무관)
| # | 작업 | 비고 |
|---|---|---|
| 1 | 비밀번호 재설정 UI | 회원이 비번 잊으면 운영자가 admin에서 초기화. 현재는 DynamoDB 직접 수정 |
| 2 | 회원 비활성화 UI | 신고 누적 사용자 차단. 현재는 `isDisabled: true` 수동 set |
| 3 | 공지사항 기능 (앱+백엔드+admin) | 청년부 일괄 안내 채널 — 앱 코드 변경 필요해 신중 |
| 4 | 차단 모니터링 미니 화면 | YAGNI로 보류. 신고로 패턴 잡기 어려워지면 도입 |

### 운영 안전망
| # | 작업 | 비고 |
|---|---|---|
| 1 | CloudWatch Alarms (Lambda 에러율, API Gateway 5xx) | 장애 자동 알림 |
| 2 | DynamoDB on-demand backup 활성화 | 데이터 손실 대비 |
| 3 | Sentry / Crashlytics | Flutter 크래시 자동 수집 (Flutter 변경 필요 — 조심) |
| 4 | Lambda 구조화 로깅 (pino 등) | 트러블슈팅 효율 |

### 기능 추가
| # | 작업 | 비고 |
|---|---|---|
| 1 | 목자 출석 입력 리마인더 푸시 (일요일 오후) | EventBridge cron 1개 추가 |
| 2 | 댓글 신고 UI + admin 본문 미리보기 | parentPrayerId 저장 확장 |
| 3 | 출석 통계 차트 (`fl_chart`) | Flutter 시각화 |
| 4 | 송리스트 (찬양팀 곡 목록) | DynamoDB or Supabase PG |
| 5 | 카카오채널 알림톡 | 카카오 비즈니스 계정 필요 |

### 코드 품질
| # | 작업 | 비고 |
|---|---|---|
| 1 | Flutter 위젯 테스트 추가 | 핵심 플로우(로그인, 기도 작성, 차단) |
| 2 | 기도 API 통합 테스트 추가 | 백엔드 회귀 방지 |
| 3 | CI/CD 파이프라인 (GitHub Actions) | PR 시 dart analyze + tsc + flutter test |

---

## 운영 SOP — 신고 콘텐츠 검토 (Privacy Policy Section 9 약속 준수)

> 개인정보처리방침에 "접수 후 24시간 이내 검토"를 명시했으므로 운영자 책임으로 매일 1회 이상 admin 패널 확인.

### 일일 절차

1. 매일 오전(예: 출근 후) admin 대시보드(`https://<admin-host>/dashboard`) 접속
2. 상단 빨간색 "미처리 신고 N건" 배너 확인 → 클릭하면 `/reports`로 이동
3. 사이드바 "신고 검토" 메뉴 옆 빨간 카운트 배지가 0이 될 때까지 처리

### 처리 결정 기준

| 상황 | 액션 | 결과 |
|---|---|---|
| 욕설, 개인정보 노출, 혐오 발언 등 명백한 위반 | **컨텐츠 삭제 + 처리** | 기도글 + 댓글 + 반응 모두 삭제, 신고 closed |
| 작성자에게 안내해서 자진 수정으로 충분 | **검토 완료** + 메모에 "작성자 안내 후 수정 확인" | 컨텐츠 유지, 신고 closed |
| 오신고/문제없음 | **무효 처리** | 컨텐츠 유지, 신고 closed |

### 반복 신고 사용자 대응

- 동일 사용자에 대한 신고가 **30일 내 3건 이상** 누적되면 회원 비활성화 검토
- 회원 비활성화는 현재 admin UI 없음 → DynamoDB Member 항목에 `isDisabled: true` 직접 set (수동)
- 비활성화 admin UI는 추후 작업 항목

### 댓글 신고 한계 (현재)

- Flutter 앱에서 댓글 신고 UI 미구현 → 백엔드는 받을 수 있지만 발생 안 함
- admin "신고 검토"에서 댓글 본문 미리보기 미지원 (parentPrayerId 미저장)
- 추후 댓글 신고를 Flutter에 추가할 때 백엔드 `report/create.ts`에 parentPrayerId도 함께 저장하도록 확장 → admin UI 자동으로 동작

---

## 참고: 현재 인프라 현황

| 서비스 | 사업자 | 리소스 | 비용 |
|---|---|---|---|
| DynamoDB | AWS | woncheon-dev (PAY_PER_REQUEST), 리전 ap-northeast-2 | 무료 (200명 규모) |
| PostgreSQL | **Supabase** | pooler `aws-1-ap-northeast-2.pooler.supabase.com:5432`, project `hhnknrrcmonvcmqlkxii` | Supabase Free Plan |
| Lambda | AWS | 20+ 함수, 단일 `dev` stage | Free Tier 범위 |
| API Gateway | AWS | REST API | Free Tier 범위 |
| SSM Parameter Store | AWS | 7개 파라미터 (PG 자격증명, JWT secret 등) | 무료 |
| S3 | AWS | Serverless 배포 아티팩트 | 거의 무료 |
| EventBridge | AWS | 주간 알림 스케줄 2개 (화 11시, 금 20시 KST) | 무료 |

> **인프라 정책**: 단일 DB / 단일 Lambda stage로 운영. dev/prod 인프라 분리 안 함. 코드 환경 분리는 git 브랜치(main=prod, dev=작업)로 처리.

> **PostgreSQL 명시**: AWS RDS가 아니라 **Supabase** 관리형 호스팅. 호스트는 ap-northeast-2이지만 사업자는 Supabase, Inc. (미국). 개인정보처리방침 Section 6에 명시됨.

---

## 참고: 활성 사용자 (= 정식 출시 후에도 그대로 사용)

| 이름 | 역할 | 비고 |
|---|---|---|
| 민동익 | 목원 | 개발자 본인 |
| 김지현 | 목자 | 비공개 테스터 |
| 조은주 | 목자 | 비공개 테스터 |
| 조성주 | 목자 | 비공개 테스터 |
| appreview | reviewer | Apple/Google 심사용 — 정식 출시 후 유지 결정 |
| 그 외 130명 | - | DB에 등록만, 실제 가입은 청년부 공지 후 진행 |
