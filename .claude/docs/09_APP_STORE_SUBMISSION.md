# 원천청년부 — App Store 심사 제출 가이드

> 모든 답안/노트 한 곳에 모아둠. App Store Connect 제출 시 이 문서를 레퍼런스로
> 그대로 복사/입력.

---

## 1. App Review Information (심사 노트)

App Store Connect → Version Information → **App Review Information** 의 **Notes** 란에
다음 영문 텍스트를 그대로 입력한다. (한국어 심사관도 많지만 안전하게 영문 권장)

```
Thank you for reviewing 원천청년부 (Woncheon Youth).

## App context
This is a private community app for registered members of the youth
ministry at Woncheon Church, a specific Korean church. All user accounts
are pre-provisioned by an administrator — there is no public sign-up.
Prospective members submit a "registration request" through the app,
which is approved manually by church staff before an account is created.

Because it is a closed, invite-only community, we have provided two
test accounts below so you can verify all features.

## Test accounts (both passwords: 11111111)

Member (목원 — regular user)
  Name: 민동익
  Role: Can write prayer requests, comment, react, view own attendance,
        block users, delete account, file reports.

Leader (목자 — small group leader)
  Name: 조성주
  Role: All member capabilities, plus: mark attendance for their small
        group members, see member-level attendance statistics.

Note: Enter the Korean name (민동익 / 조성주) exactly as shown — these are
the login identifiers. The password field accepts plain text.

## Content moderation workflow (Guideline 1.2)

- In-app Report button on every prayer and comment, with 6 report categories
- In-app Block feature on non-anonymous prayers (prevents blocked users'
  content from appearing anywhere)
- Block management screen in Settings, allowing users to unblock any previously
  blocked member
- Reports are reviewed within 24 hours by our admin team via a separate,
  internal web-based moderation dashboard (not part of this iOS submission).
  Abusive content is removed and repeat offenders are banned.
- In-app user support contact (email + phone) is shown in Settings.

## Account deletion (Guideline 5.1.1(v))

In-app "Delete account" (설정 → 계정 삭제). Two-step confirmation.
Deletes all user content (prayers, comments, reactions) and personal data
from our servers.

## Push notifications

Push notifications are sent weekly (Saturday 20:00 KST) by an AWS
EventBridge schedule, notifying members of new prayer requests from the
past week. During review, you can trigger a local test notification by:
1. Logging in with either test account
2. Granting notification permission when prompted
3. The next scheduled push will fire on the upcoming Saturday

If you need an immediate push test, please let us know via Resolution
Center and we can trigger one manually.

## Data & privacy

- No third-party analytics or advertising SDKs
- All data stored in AWS (DynamoDB for members/prayers/comments,
  RDS PostgreSQL for attendance). Region: ap-northeast-2 (Seoul).
- Privacy policy: https://douglasmin.github.io/flutter-woncheon-youth-app/

## Language

The app UI is Korean-only. The core flows (login, prayer list, prayer
detail, attendance, settings) are visually clear and should be navigable
even without Korean reading ability. If any flow is unclear, please
contact us.

## Developer contact
Email: dongik.dev73@gmail.com
Phone: +82 10 4414 0703
```

### 공용 필드
- **Sign-in required**: YES
- **Demo account**: see 테스트 계정 above (Notes 란에만 입력해도 Apple은 거기서 읽음)

---

## 2. App Privacy 질문 답안 (App Store Connect → App Privacy)

App Store Connect에서 제출 전 반드시 채워야 하는 데이터 수집 설문. 아래 그대로
체크.

### Data Types Collected

아래 항목만 체크. 나머지 전부 "Not Collected".

#### Contact Info
- ✅ **Name**
  - Used for: **App Functionality**
  - Linked to User: **Yes**
  - Used for Tracking: **No**

#### User Content
- ✅ **Other User Content** (기도글, 댓글, 신고 사유)
  - Used for: **App Functionality**
  - Linked to User: **Yes**
  - Used for Tracking: **No**

#### Identifiers
- ✅ **User ID** (내부 memberId)
  - Used for: **App Functionality**, **Authentication**
  - Linked to User: **Yes**
  - Used for Tracking: **No**
- ✅ **Device ID** (푸시 알림용 디바이스 토큰)
  - Used for: **App Functionality**
  - Linked to User: **Yes**
  - Used for Tracking: **No**

#### Usage Data
- ✅ **Product Interaction** (출석 기록 — 주일별 present/absent)
  - Used for: **App Functionality**
  - Linked to User: **Yes**
  - Used for Tracking: **No**

#### Diagnostics
- ❌ None

#### Financial / Health / Location / Sensitive / Purchases / Browsing / Search / Audio / Photos / Video / Contacts
- ❌ None

### Tracking Question
**"Do you or your third-party partners use data from this app for the
purpose of tracking?"**
→ **No**

(우리는 광고 네트워크나 분석 SDK를 사용하지 않으며 데이터는 AWS 내부에만
저장됨)

---

## 3. 연령 등급 설문 (Age Rating)

App Store Connect → Age Rating 설문. 아래대로 응답.

| 질문 카테고리 | 답변 |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Contests | None |
| **Unrestricted Web Access** | No |
| Gambling and Contests | No |

추가 질문:
- **User Generated Content available to the general public?** → **No**
  (폐쇄형 커뮤니티 — 등록된 교회 회원만 콘텐츠 생성/열람 가능)

**결과 예상 등급: 4+**

---

## 4. 기타 App Store Connect 필드

### General
- **Category** — Primary: Lifestyle, Secondary: Social Networking (선택)
- **Content Rights** — 직접 만든 콘텐츠만 사용. "Does your app contain,
  display, or access third-party content?" → **No**

### Version Information
- **Description (ko)**:
  ```
  원천청년부는 원천교회 청년부원을 위한 비공개 커뮤니티 앱입니다.

  주요 기능:
  • 중보기도 — 기도 제목을 익명 또는 실명으로 나누고 함께 기도해요
  • 댓글과 🙏 반응으로 서로를 응원해요
  • 목장 페이지 — 우리 목장 목원들의 출석과 기도 제목을 한눈에
  • 출석 관리 — 목자가 주일 예배 출석을 기록하고, 목원은 본인 출석률 확인

  안전 기능:
  • 부적절한 콘텐츠 신고
  • 사용자 차단 및 차단 관리
  • 계정 삭제로 모든 데이터 영구 삭제

  가입은 교회 관리자의 사전 승인으로만 가능합니다.
  ```

- **Keywords (ko)**: `원천교회,청년부,중보기도,기도,교회,목장,공동체`
- **Support URL**: `https://douglasmin.github.io/flutter-woncheon-youth-app/`
  (지금은 Privacy Policy와 동일. 가능하면 별도 support 페이지 or
   contact form 추가 권장)
- **Marketing URL**: (선택사항, 없으면 비워둠)
- **Privacy Policy URL**: `https://douglasmin.github.io/flutter-woncheon-youth-app/`

---

## 5. End-to-End 배포 플로우 (Apple Developer 활성화 후)

전체 소요 시간: 반나절 ~ 1일 (Xcode 빌드 + 업로드 + propagation 포함)

### Phase 1 — Apple Developer Console

```
developer.apple.com → Certificates, IDs & Profiles
```

**1-1. Bundle ID 등록 (Identifiers)**
- `+` → App IDs → App → Continue
- Description: `Woncheon Youth`
- Bundle ID: Explicit → `com.woncheon.woncheonYouth`
- Capabilities: **Push Notifications** 체크
- Continue → Register

**1-2. APNs Auth Key (.p8) 발급 (Keys)**
- `+` → Key Name: `Woncheon Youth APNs`
- Enable: **Apple Push Notifications service (APNs)** 체크
- Continue → Register
- **`.p8` 파일 다운로드 — 한 번만 받을 수 있음. 안전한 곳에 백업**
- Key ID 기록 (10자리), Team ID 기록 (Membership 탭)

### Phase 2 — AWS SNS Platform Application

**AWS Console → SNS (ap-northeast-2) → Mobile → Push notifications → Create platform application**

**dev (sandbox) 용:**
- Name: `woncheon-youth-ios-dev`
- Platform: **Apple iOS/VoIP Services** + **Use for development in sandbox** 체크
- Authentication method: Token (권장)
- Signing key: .p8 파일 내용 전체 붙여넣기
- Signing key ID: (Phase 1-2에서 기록한 Key ID)
- Team ID: (Team ID)
- Bundle ID: `com.woncheon.woncheonYouth`
- Create
- → 생성된 Platform ARN 복사 (예: `arn:aws:sns:ap-northeast-2:863518440691:app/APNS_SANDBOX/woncheon-youth-ios-dev`)

**prod 용:**
- 동일 절차 but 이름은 `woncheon-youth-ios-prod`
- **Use for development in sandbox 체크 해제** (= production APNS)

### Phase 3 — SSM 파라미터 (SNS ARN 등록)

```bash
# dev
AWS_PROFILE=dongik2 aws ssm put-parameter \
  --region ap-northeast-2 \
  --name "/woncheon/dev/sns-ios-arn" \
  --value "arn:aws:sns:ap-northeast-2:863518440691:app/APNS_SANDBOX/woncheon-youth-ios-dev" \
  --type String --overwrite

# prod
AWS_PROFILE=dongik2 aws ssm put-parameter \
  --region ap-northeast-2 \
  --name "/woncheon/prod/sns-ios-arn" \
  --value "arn:aws:sns:ap-northeast-2:863518440691:app/APNS/woncheon-youth-ios-prod" \
  --type String --overwrite
```

이후 Lambda 재배포 필요 (환경 변수로 ARN 주입되므로):
```bash
cd woncheon-backend && AWS_PROFILE=dongik2 pnpm deploy:dev
```

### Phase 4 — iOS 프로젝트 설정

```bash
open ios/Runner.xcworkspace
```

- **Signing & Capabilities** 탭
  - Team: 본인 Apple Developer 팀 선택
  - Automatically manage signing 체크 (간편)
  - **+ Capability** → "Push Notifications" 추가
- **Runner.entitlements** 확인:
  - dev 빌드: `aps-environment: development`
  - prod/TestFlight 빌드: `aps-environment: production`

### Phase 5 — 실기기 푸시 테스트 (dev)

1. 본인 iPhone USB 연결 + "이 컴퓨터 신뢰" 승인
2. Xcode에서 본인 디바이스 선택 or `flutter devices`에서 확인
3. `flutter run -d <device-id>`
4. 앱 실행 → 로그인 → 알림 권한 허용
5. 디바이스 토큰이 SSN에 등록되는지 확인:
   - Xcode console에서 `[Push] APNs token received` 같은 로그
   - AWS SNS → Platform applications → 해당 app → **Endpoints** 목록에 추가됐는지
6. **앱 내 설정 → "테스트 알림 받기"** 버튼 탭
7. 몇 초 내 알림 배너 도착 확인
8. 앱 백그라운드로 보낸 후 (Cmd+Shift+H 해당하는 제스처) 다시 테스트 → 락스크린 푸시 확인
9. 푸시 탭 시 기도 리스트로 딥링크 이동 확인

### Phase 6 — prod 백엔드 배포

```bash
# DB 마이그레이션 (prod PG가 dev와 같은 Supabase면 스킵. 분리했으면 필요)
# 현재는 dev Supabase 공유 방침

cd woncheon-backend && AWS_PROFILE=dongik2 pnpm deploy:prod
```

배포 후 prod API Gateway URL 복사 (콘솔 출력에서):
예: `https://abcd1234ef.execute-api.ap-northeast-2.amazonaws.com/prod`

`lib/core/constants.dart`의 `apiBaseUrlProd` 업데이트:
```dart
static const String apiBaseUrlProd =
    'https://abcd1234ef.execute-api.ap-northeast-2.amazonaws.com/prod';
```

### Phase 7 — 데이터 정리 (prod 첫 출시 전 1회)

Dev Supabase를 prod로 재사용 중이므로 test 데이터 정리:

```sql
-- test 출석 기록 삭제 (557건)
DELETE FROM attendance;
-- groups, group_members는 실 청년부 데이터이므로 유지
```

DynamoDB는 `woncheon-prod` 테이블이 배포 시 새로 생성되므로 자동으로 깨끗함.

테스트 계정 비밀번호 초기화:
```bash
# 민동익, 김지현, 조은주, 조성주를 isFirstLogin: true 로 리셋
# scripts/reset-test-passwords.ts (작성 필요)
```

### Phase 8 — Flutter prod 빌드

**`pubspec.yaml` version 업데이트:**
```yaml
version: 1.0.0+1
```

**prod 아카이브:**
```bash
flutter build ipa --release --dart-define=ENV=prod
```

`build/ios/ipa/*.ipa` 생성됨.

또는 Xcode로:
- Product → Scheme → Edit Scheme → Run → Arguments → Arguments Passed On Launch: `--dart-define=ENV=prod`
- Product → Archive
- Window → Organizer → Distribute App → App Store Connect → Upload

### Phase 9 — App Store Connect 앱 생성 + 메타데이터

[https://appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → `+` → New App

- Platforms: iOS
- Name: 원천청년부
- Primary language: Korean
- Bundle ID: `com.woncheon.woncheonYouth`
- SKU: `woncheon-youth-001` (임의, 고유)
- User Access: Full Access

생성 후 이 문서의 섹션 1~4 참고해서 모든 필드 입력.

### Phase 10 — TestFlight 내부 테스트 (권장)

- TestFlight 탭 → Internal Testing → 테스터 추가 (이메일)
- 자신 + 청년부 리더 3~5명
- 빌드 선택 → 그룹에 배포
- 테스터가 TestFlight 앱에서 원천청년부 설치 → 실사용 테스트 1~2일
- 중대한 버그 없으면 다음 단계

### Phase 11 — Submit for Review

- App Store Connect → 버전 페이지
- "Submit for Review" 버튼
- Export Compliance 등 마지막 질문:
  - "Does your app use encryption?" → **No** (HTTPS만 사용, 자체 암호화 알고리즘 없음)
- 제출 완료

### Phase 12 — 심사 진행 중

- 일반적 소요: **24~48시간** (첫 제출은 더 걸릴 수 있음)
- Resolution Center에 피드백/거부 사유 오면 대응 (섹션 6 참고)
- 승인되면 "Ready for Sale" 상태
- Release 타입에 따라 즉시/수동/예약 출시

---

## 6. 심사 도중 리스크 & 대응

| 리스크 | 발생 시 대응 |
|---|---|
| 심사관이 한국어 모름 → 플로우 이해 못 함 | Resolution Center에 영상 링크 (YouTube unlisted) 첨부 |
| "Sign in with Apple" 요구 | 답변: 자체 로그인만 사용 (3rd-party 로그인 미사용) + 폐쇄 커뮤니티 예외 조항 인용 |
| "모더레이션 증거 요청" | 관리자 대시보드 스크린샷 1~2장 첨부 (신고 목록 페이지) |
| 푸시 테스트 요구 | Resolution Center로 "수동 발송 요청" 받으면 EventBridge rule 즉시 invoke |
| 부적절 콘텐츠 발견 | 심사 전 샌드박스 계정 세팅으로 사전 방지 (다음 섹션) |

---

## 문서 마지막 업데이트
2026-04-19

> 참고: 심사 시점 DB 상태 — 심사 통과 후 청년부원에게 배포할 예정이므로
> 현재 DB의 기도문/댓글은 모두 개발 중 작성된 test 데이터이며, 심사관에게
> 노출돼도 실제 유저 privacy 문제 없음. 샌드박스 계정 별도 세팅 불필요.
