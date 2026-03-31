# 원천청년부 앱 — API 명세서

## 공통 사항

**Base URL**
```
dev:  https://{api-id}.execute-api.ap-northeast-2.amazonaws.com/dev
prod: https://{api-id}.execute-api.ap-northeast-2.amazonaws.com/prod
```

**공통 헤더**
```
Content-Type: application/json
Authorization: Bearer {accessToken}   ← 인증 필요 API에만
```

**공통 응답 형식**
```json
// 성공
{
  "success": true,
  "data": { ... }
}

// 실패
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "에러 메시지"
  }
}
```

**공통 에러 코드**

| HTTP | code | 설명 |
|---|---|---|
| 400 | VALIDATION_ERROR | 요청 파라미터 오류 |
| 401 | UNAUTHORIZED | 토큰 없음 또는 만료 |
| 403 | FORBIDDEN | 권한 없음 (타인 리소스 접근) |
| 404 | NOT_FOUND | 리소스 없음 |
| 500 | INTERNAL_ERROR | 서버 내부 오류 |

---

## 1. 인증 (Auth)

### POST /auth/login
로그인. 이름 + 비밀번호 검증 후 JWT 발급.

**인증 불필요**

**Request Body**
```json
{
  "name": "홍길동",
  "password": "woncheon2025"
}
```

**Response 200**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGci...",
    "refreshToken": "eyJhbGci...",
    "isFirstLogin": true,          // true면 클라이언트에서 비번 변경 화면으로 강제 이동
    "member": {
      "memberId": "01J9XYZABC",
      "name": "홍길동"
    }
  }
}
```

**에러 케이스**
| 상황 | HTTP | code |
|---|---|---|
| 교적부 미등록 이름 | 401 | MEMBER_NOT_FOUND |
| 비밀번호 불일치 | 401 | INVALID_PASSWORD |

---

### POST /auth/change-password
비밀번호 변경. 최초 로그인 시 필수.

**인증 필요 (Bearer)**

**Request Body**
```json
{
  "currentPassword": "woncheon2025",
  "newPassword": "myNewPw123"
}
```

**Response 200**
```json
{
  "success": true,
  "data": {
    "message": "비밀번호가 변경되었습니다."
  }
}
```

**에러 케이스**
| 상황 | HTTP | code |
|---|---|---|
| 현재 비밀번호 불일치 | 400 | INVALID_CURRENT_PASSWORD |
| 새 비밀번호 8자 미만 | 400 | VALIDATION_ERROR |
| 현재 비밀번호와 동일 | 400 | SAME_AS_CURRENT_PASSWORD |

---

### POST /auth/refresh
Access Token 재발급.

**인증 불필요**

**Request Body**
```json
{
  "refreshToken": "eyJhbGci..."
}
```

**Response 200**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGci...",
    "refreshToken": "eyJhbGci..."   // Refresh Token도 함께 갱신 (Rotation)
  }
}
```

**에러 케이스**
| 상황 | HTTP | code |
|---|---|---|
| 유효하지 않은 Refresh Token | 401 | INVALID_REFRESH_TOKEN |
| 만료된 Refresh Token | 401 | REFRESH_TOKEN_EXPIRED |

---

### POST /auth/device-token
FCM/APNs 디바이스 토큰 등록 (푸시 알림 수신 동의 후 호출).

**인증 필요 (Bearer)**

**Request Body**
```json
{
  "token": "fcm-or-apns-device-token-string",
  "platform": "ios"    // "ios" | "android"
}
```

**Response 200**
```json
{
  "success": true,
  "data": {
    "message": "토큰이 등록되었습니다."
  }
}
```

---

## 2. 중보기도 (Prayer)

### GET /prayers
중보기도 목록 조회. 최신순, 커서 기반 페이지네이션.

**인증 필요 (Bearer)**

**Query Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| limit | Number | No | 한 번에 가져올 수 (기본값: 20, 최대: 50) |
| cursor | String | No | 이전 응답의 nextCursor 값 (첫 요청 시 생략) |

**Response 200**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "prayerId": "01J9XYZDEF",
        "authorName": "익명",
        "isAnonymous": true,
        "contentPreview": "취업 준비 중인데 주님의 인도하심을...",  // 최대 100자 미리보기
        "createdAt": "2025-03-01T10:00:00Z"
      },
      {
        "prayerId": "01J9XYZGHI",
        "authorName": "김철수",
        "isAnonymous": false,
        "contentPreview": "가족의 건강을 위해 기도 부탁드립니다.",
        "createdAt": "2025-02-28T08:30:00Z"
      }
    ],
    "nextCursor": "eyJQSyI6...",   // 다음 페이지 없으면 null
    "hasMore": true
  }
}
```

---

### POST /prayers
중보기도 작성.

**인증 필요 (Bearer)**

**Request Body**
```json
{
  "content": "취업 준비 중인데 주님의 인도하심을 구합니다.",
  "isAnonymous": true
}
```

**Response 201**
```json
{
  "success": true,
  "data": {
    "prayerId": "01J9XYZDEF",
    "authorName": "익명",
    "isAnonymous": true,
    "content": "취업 준비 중인데 주님의 인도하심을 구합니다.",
    "createdAt": "2025-03-01T10:00:00Z"
  }
}
```

**에러 케이스**
| 상황 | HTTP | code |
|---|---|---|
| content 없음 또는 빈 문자열 | 400 | VALIDATION_ERROR |
| content 500자 초과 | 400 | VALIDATION_ERROR |

---

### GET /prayers/{prayerId}
중보기도 상세 조회.

**인증 필요 (Bearer)**

**Path Parameters**
| 파라미터 | 설명 |
|---|---|
| prayerId | 중보기도 ID |

**Response 200**
```json
{
  "success": true,
  "data": {
    "prayerId": "01J9XYZDEF",
    "authorName": "익명",
    "isAnonymous": true,
    "content": "취업 준비 중인데 주님의 인도하심을 구합니다.",
    "createdAt": "2025-03-01T10:00:00Z",
    "isMine": false    // 본인 작성글 여부 (삭제 버튼 노출 용도)
  }
}
```

---

### DELETE /prayers/{prayerId}
중보기도 삭제. 본인 작성글만 가능.

**인증 필요 (Bearer)**

**Path Parameters**
| 파라미터 | 설명 |
|---|---|
| prayerId | 삭제할 중보기도 ID |

**Response 200**
```json
{
  "success": true,
  "data": {
    "message": "삭제되었습니다."
  }
}
```

**에러 케이스**
| 상황 | HTTP | code |
|---|---|---|
| 존재하지 않는 prayerId | 404 | NOT_FOUND |
| 본인 작성글 아님 | 403 | FORBIDDEN |

---

## 3. Lambda Authorizer 동작

API Gateway Lambda Authorizer를 사용하여 JWT 검증.

```
클라이언트 요청
  → API Gateway
  → Lambda Authorizer 호출
      └─ Authorization 헤더에서 Bearer 토큰 추출
      └─ JWT 검증 (서명, 만료 시간)
      └─ 유효: Allow 정책 반환 + Context에 memberId 주입
      └─ 무효: Deny 정책 반환 (401)
  → 실제 Lambda 함수 호출 (Context에서 memberId 사용)
```

Lambda 함수 내에서 `event.requestContext.authorizer.memberId`로 현재 사용자 식별.

---

## 4. EventBridge 스케줄 (주간 알림)

**스케줄**: `cron(0 11 ? * SAT *)` (UTC 기준 토요일 11:00 = KST 20:00)

**트리거**: `notification/sendWeekly` Lambda

**로직**
1. 이번 주 월요일 00:00 KST 이후 생성된 PrayerRequest 수 집계
2. count == 0이면 종료
3. GSI3에서 전체 DeviceToken 조회
4. SNS `publish`로 각 endpoint에 푸시 발송
5. NotificationLog 저장

**발송 메시지 payload (FCM/APNs)**
```json
{
  "notification": {
    "title": "원천청년부",
    "body": "이번 주 3개의 중보기도가 올라왔어요 🙏"
  },
  "data": {
    "screen": "prayer_list"    // 딥링크: 중보기도 목록으로 이동
  }
}
```
