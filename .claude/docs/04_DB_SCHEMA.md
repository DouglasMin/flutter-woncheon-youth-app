# 원천청년부 앱 — DynamoDB 스키마 설계

## 기본 원칙

- **Single Table Design** 적용
- 테이블명: `woncheon-${stage}`
- 기본 키: `PK` (String) + `SK` (String)
- GSI 최소화, 필요한 Access Pattern 기반으로만 추가

---

## 1. 엔티티 목록

| 엔티티 | 설명 |
|---|---|
| Member | 청년부원 (회원 정보, 인증) |
| RefreshToken | JWT Refresh Token 저장 |
| PrayerRequest | 중보기도 게시물 |
| DeviceToken | 푸시 알림용 디바이스 토큰 |
| NotificationLog | 푸시 알림 발송 기록 |

---

## 2. Access Pattern 정의

| # | 설명 | 조회 방식 |
|---|---|---|
| AP-01 | 이름으로 회원 조회 (로그인) | GSI1: `NAME#{name}` |
| AP-02 | memberId로 회원 조회 | PK=`MEMBER#{memberId}`, SK=`#META` |
| AP-03 | Refresh Token 조회/삭제 | PK=`MEMBER#{memberId}`, SK=`TOKEN#{token}` |
| AP-04 | 중보기도 전체 목록 (최신순, 페이지네이션) | GSI2: PK=`PRAYER_LIST`, SK=`{createdAt}#{prayerId}` |
| AP-05 | 중보기도 단건 조회 | PK=`PRAYER#{prayerId}`, SK=`#META` |
| AP-06 | 이번 주 중보기도 수 집계 | GSI2 SK 범위 쿼리 (이번 주 월~일) |
| AP-07 | 회원별 디바이스 토큰 전체 조회 | PK=`MEMBER#{memberId}`, SK begins_with `DEVICE#` |
| AP-08 | 전체 디바이스 토큰 조회 (알림 발송용) | GSI3: PK=`ALL_DEVICES` |

---

## 3. 테이블 스키마

### 테이블 기본 구성

| 속성 | 타입 | 설명 |
|---|---|---|
| PK | String | Partition Key |
| SK | String | Sort Key |
| GSI1PK | String | GSI1 Partition Key |
| GSI1SK | String | GSI1 Sort Key |
| GSI2PK | String | GSI2 Partition Key |
| GSI2SK | String | GSI2 Sort Key |
| GSI3PK | String | GSI3 Partition Key |

---

### 3-1. Member

```
PK            = "MEMBER#{memberId}"
SK            = "#META"
GSI1PK        = "NAME#{name}"         ← 이름으로 로그인 조회용
GSI1SK        = "#META"

속성:
  memberId      : String (ulid)
  name          : String
  passwordHash  : String (bcrypt)
  isFirstLogin  : Boolean
  createdAt     : String (ISO 8601)
  updatedAt     : String (ISO 8601)
```

**예시**
```json
{
  "PK": "MEMBER#01J9XYZABC",
  "SK": "#META",
  "GSI1PK": "NAME#홍길동",
  "GSI1SK": "#META",
  "memberId": "01J9XYZABC",
  "name": "홍길동",
  "passwordHash": "$2b$10$...",
  "isFirstLogin": false,
  "createdAt": "2025-01-01T00:00:00Z",
  "updatedAt": "2025-01-05T12:00:00Z"
}
```

---

### 3-2. RefreshToken

```
PK  = "MEMBER#{memberId}"
SK  = "TOKEN#{refreshToken}"

속성:
  memberId   : String
  token      : String
  expiresAt  : Number (Unix timestamp, TTL 속성으로 설정)
  createdAt  : String
```

> TTL 속성: `expiresAt` → DynamoDB TTL 활성화로 만료 토큰 자동 삭제

---

### 3-3. PrayerRequest

```
PK     = "PRAYER#{prayerId}"
SK     = "#META"
GSI2PK = "PRAYER_LIST"
GSI2SK = "{createdAt}#{prayerId}"   ← 시간순 정렬, 페이지네이션

속성:
  prayerId    : String (ulid)
  memberId    : String
  authorName  : String              ← 익명이면 "익명", 실명이면 실제 이름
  isAnonymous : Boolean
  content     : String (최대 500자)
  createdAt   : String (ISO 8601)
```

**예시**
```json
{
  "PK": "PRAYER#01J9XYZDEF",
  "SK": "#META",
  "GSI2PK": "PRAYER_LIST",
  "GSI2SK": "2025-03-01T10:00:00Z#01J9XYZDEF",
  "prayerId": "01J9XYZDEF",
  "memberId": "01J9XYZABC",
  "authorName": "익명",
  "isAnonymous": true,
  "content": "취업 준비 중인데 주님의 인도하심을 구합니다.",
  "createdAt": "2025-03-01T10:00:00Z"
}
```

---

### 3-4. DeviceToken

```
PK     = "MEMBER#{memberId}"
SK     = "DEVICE#{platform}#{token}"
GSI3PK = "ALL_DEVICES"              ← 전체 토큰 스캔용 (알림 발송)

속성:
  memberId    : String
  token       : String (FCM or APNs 토큰)
  platform    : String ("ios" | "android")
  snsEndpoint : String (SNS Platform Endpoint ARN)
  createdAt   : String
```

> `snsEndpoint`: 최초 토큰 등록 시 SNS `createPlatformEndpoint` 호출 결과 ARN 저장.
> 이후 알림 발송은 endpoint ARN으로 직접 발송 (토큰 매번 재등록 방지).

---

### 3-5. NotificationLog

```
PK  = "NOTIF_LOG"
SK  = "{sentAt}"

속성:
  sentAt         : String (ISO 8601)
  newPrayerCount : Number
  recipientCount : Number
  status         : String ("success" | "partial_fail")
```

---

## 4. GSI 구성 요약

| GSI 이름 | PK | SK | 용도 |
|---|---|---|---|
| GSI1 | GSI1PK | GSI1SK | 이름으로 회원 조회 (로그인) |
| GSI2 | GSI2PK | GSI2SK | 중보기도 전체 목록 (시간순) |
| GSI3 | GSI3PK | - | 전체 디바이스 토큰 조회 |

---

## 5. 페이지네이션 전략

중보기도 목록 (AP-04) 는 DynamoDB의 `LastEvaluatedKey`를 활용한 커서 기반 페이지네이션 적용.

- 요청: `GET /prayers?limit=20&cursor={base64EncodedLastKey}`
- 응답:
```json
{
  "items": [...],
  "nextCursor": "eyJQSyI6...",   // LastEvaluatedKey를 base64 인코딩
  "hasMore": true
}
```

- `nextCursor`가 `null`이면 마지막 페이지
- GSI2 `ScanIndexForward: false` → 최신순 (내림차순) 정렬

---

## 6. 이번 주 중보기도 집계 방법 (알림용)

```typescript
// 이번 주 월요일 00:00 KST 계산
const startOfWeek = getStartOfWeekKST(); // ISO string

// GSI2에서 범위 쿼리
const result = await dynamodb.query({
  TableName: TABLE_NAME,
  IndexName: 'GSI2',
  KeyConditionExpression: 'GSI2PK = :pk AND GSI2SK >= :start',
  ExpressionAttributeValues: {
    ':pk': 'PRAYER_LIST',
    ':start': startOfWeek,
  },
  Select: 'COUNT',
});

const count = result.Count;
```
