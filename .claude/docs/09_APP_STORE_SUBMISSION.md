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

## 5. Build 업로드 전 체크리스트

- [ ] `pubspec.yaml`의 version + build number 올림 (예: `1.0.0+1`)
- [ ] `kMockMode = false` 확인
- [ ] API URL이 **dev가 아닌 prod**를 가리키게 `--dart-define=ENV=prod` 빌드
- [ ] Runner.entitlements에 `aps-environment: production` 설정 (APNs Key 발급 후)
- [ ] Xcode에서 Archive → Distribute → App Store Connect 업로드
- [ ] App Store Connect에서 빌드 선택 + 위 4개 섹션 모두 채움
- [ ] 스크린샷 업로드 (6.9" iPhone, 6.5" iPhone 최소 각 3장)
- [ ] **Submit for Review**

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
