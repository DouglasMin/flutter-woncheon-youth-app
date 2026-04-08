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
| Comment | 중보기도 댓글 |
| Reaction | 중보기도 반응 (🙏) |
| DeviceToken | 푸시 알림용 디바이스 토큰 |
| NotificationLog | 푸시 알림 발송 기록 |
| Report | 콘텐츠 신고 |

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
| AP-09 | 기도별 댓글 목록 (시간순) | PK=`PRAYER#{prayerId}`, SK begins_with `COMMENT#` |
| AP-10 | 기도별 반응 수 + 본인 반응 여부 | PK=`PRAYER#{prayerId}`, SK=`REACTION#{memberId}` / SK begins_with `REACTION#` |
| AP-11 | 기도 cascade 삭제 (기도+댓글+반응) | PK=`PRAYER#{prayerId}` 전체 조회 → BatchWriteCommand |
| AP-12 | 계정 삭제 (회원 데이터 전체) | MEMBER# prefix 삭제 + GSI2 필터로 기도 찾기 → cascade |

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
  birthDate     : String
  gender        : String ("M" | "W")
  createdAt     : String (ISO 8601)
  updatedAt     : String (ISO 8601)
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

> 삭제 시 PK=`PRAYER#{prayerId}` 하위 모든 아이템(#META + COMMENT# + REACTION#) cascade 삭제

---

### 3-4. Comment

```
PK  = "PRAYER#{prayerId}"          ← 기도와 같은 파티션
SK  = "COMMENT#{createdAt}#{commentId}"

속성:
  commentId   : String (ulid)
  prayerId    : String
  memberId    : String
  authorName  : String
  content     : String (최대 200자)
  createdAt   : String (ISO 8601)
```

> 조회: PK=`PRAYER#{prayerId}` AND SK begins_with `COMMENT#` → 시간순 정렬

---

### 3-5. Reaction

```
PK  = "PRAYER#{prayerId}"          ← 기도와 같은 파티션
SK  = "REACTION#{memberId}"        ← 1인 1반응 보장 (toggle)

속성:
  prayerId    : String
  memberId    : String
  createdAt   : String (ISO 8601)
```

> 토글: GetItem → 존재하면 DeleteItem, 없으면 PutItem
> 카운트: PK=`PRAYER#{prayerId}` AND SK begins_with `REACTION#` → COUNT

---

### 3-6. DeviceToken

```
PK     = "MEMBER#{memberId}"
SK     = "DEVICE#{platform}#{token}"
GSI3PK = "ALL_DEVICES"              ← 전체 토큰 스캔용 (알림 발송)

속성:
  memberId    : String
  token       : String (APNs 토큰)
  platform    : String ("ios" | "android")
  snsEndpoint : String (SNS Platform Endpoint ARN)
  createdAt   : String
```

---

### 3-7. NotificationLog

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

### 3-8. Report

```
PK  = "REPORT#{reportId}"
SK  = "#META"

속성:
  reportId          : String (ulid)
  reporterMemberId  : String
  targetType        : String ("prayer" | "comment")
  targetId          : String (prayerId or commentId)
  reason            : String
  status            : String ("pending" | "resolved")
  createdAt         : String (ISO 8601)
```

---

## 4. GSI 구성 요약

| GSI 이름 | PK | SK | 용도 |
|---|---|---|---|
| GSI1 | GSI1PK | GSI1SK | 이름으로 회원 조회 (로그인) |
| GSI2 | GSI2PK | GSI2SK | 중보기도 전체 목록 (시간순) |
| GSI3 | GSI3PK | - | 전체 디바이스 토큰 조회 |

---

## 5. 아이템 컬렉션 패턴

기도 파티션(`PK = PRAYER#{prayerId}`) 하위에 관련 엔티티가 모여있음:

```
PRAYER#abc123  |  #META                              ← 기도 본문
PRAYER#abc123  |  COMMENT#2026-04-08T10:00:00Z#cmt1  ← 댓글 1
PRAYER#abc123  |  COMMENT#2026-04-08T11:00:00Z#cmt2  ← 댓글 2
PRAYER#abc123  |  REACTION#member001                  ← 반응 1
PRAYER#abc123  |  REACTION#member002                  ← 반응 2
```

→ 단일 Query로 기도 + 댓글 + 반응 전부 조회 가능
→ 기도 삭제 시 PK 전체 삭제로 cascade 처리

---

## 6. 페이지네이션 전략

중보기도 목록 (AP-04) 는 DynamoDB의 `LastEvaluatedKey`를 활용한 커서 기반 페이지네이션 적용.

- 요청: `GET /prayers?limit=20&cursor={base64EncodedLastKey}`
- 응답:
```json
{
  "items": [...],
  "nextCursor": "eyJQSyI6...",
  "hasMore": true
}
```

- `nextCursor`가 `null`이면 마지막 페이지
- GSI2 `ScanIndexForward: false` → 최신순 (내림차순) 정렬
- 날짜 필터: `startDate`, `endDate` 쿼리 파라미터로 GSI2SK 범위 쿼리

---

## 7. Cascade 삭제 패턴

공유 유틸: `libs/batch-delete.ts` → `deleteItemsByPK(pk, skPrefix?)`

- 페이지네이션: `LastEvaluatedKey` 루프
- 배치: 25개씩 `BatchWriteCommand`
- 재시도: `UnprocessedItems` 자동 retry (100ms backoff)
- Limit: 250 per query page

### 기도 삭제
```
deleteItemsByPK("PRAYER#{prayerId}")
→ #META + COMMENT#* + REACTION#* 전부 삭제
```

### 계정 삭제
```
1. deleteItemsByPK("MEMBER#{memberId}", "TOKEN#")    ← Refresh Tokens
2. deleteItemsByPK("MEMBER#{memberId}", "DEVICE#")   ← Device Tokens
3. GSI2 Query (FilterExpression: memberId) → 각 기도 cascade 삭제
4. DeleteItem("MEMBER#{memberId}", "#META")           ← 마지막에 META 삭제
```

---

## 8. PostgreSQL 스키마 (출결 관리)

별도 RDS PostgreSQL (db.t4g.micro) 사용. DynamoDB와 `memberId`로 연결.

```sql
groups (id, name, leader_member_id)
group_members (group_id, member_id, member_name, note)
attendance (group_id, member_id, attendance_date, is_present, checked_by)
```

- 일요일 제약: `CHECK (EXTRACT(DOW FROM attendance_date) = 0)`
- FK: `attendance → group_members (group_id, member_id)`
- Timezone: 커넥션 레벨 `SET timezone = 'Asia/Seoul'`

상세 스키마: `woncheon-backend/sql/001_create_tables.sql`
