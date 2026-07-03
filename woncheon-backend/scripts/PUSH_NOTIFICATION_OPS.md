# 푸시 알림 운영 가이드

## 전제 조건

- 사용자가 앱에서 **최초 로그인** 해야 디바이스 토큰이 SNS에 등록됨
- 로그인 시 앱이 `POST /auth/device-token` 호출 → SNS Platform Endpoint 생성
- AWS Profile: `dongik2`, Region: `ap-northeast-2`

---

## SNS Platform Application ARNs

| 플랫폼 | ARN |
|--------|-----|
| iOS (Production) | `arn:aws:sns:ap-northeast-2:863518440691:app/APNS/woncheon-ios` |
| iOS (Sandbox) | `arn:aws:sns:ap-northeast-2:863518440691:app/APNS_SANDBOX/woncheon-ios-sandbox` |
| Android (FCM) | `arn:aws:sns:ap-northeast-2:863518440691:app/GCM/woncheon-android` |

---

## 엔드포인트 조회

### iOS 전체

```bash
aws sns list-endpoints-by-platform-application \
  --platform-application-arn "arn:aws:sns:ap-northeast-2:863518440691:app/APNS/woncheon-ios" \
  --region ap-northeast-2 --profile dongik2 \
  --query 'Endpoints[*].{Arn:EndpointArn,Enabled:Attributes.Enabled}' \
  --output table
```

### Android 전체

```bash
aws sns list-endpoints-by-platform-application \
  --platform-application-arn "arn:aws:sns:ap-northeast-2:863518440691:app/GCM/woncheon-android" \
  --region ap-northeast-2 --profile dongik2 \
  --query 'Endpoints[*].{Arn:EndpointArn,Enabled:Attributes.Enabled}' \
  --output table
```

### 통합 (iOS + Android 카운트)

```bash
echo "=== iOS ===" && \
aws sns list-endpoints-by-platform-application \
  --platform-application-arn "arn:aws:sns:ap-northeast-2:863518440691:app/APNS/woncheon-ios" \
  --region ap-northeast-2 --profile dongik2 \
  --query 'length(Endpoints[?Attributes.Enabled==`true`])' --output text | xargs -I{} echo "  Active: {}" && \
echo "=== Android ===" && \
aws sns list-endpoints-by-platform-application \
  --platform-application-arn "arn:aws:sns:ap-northeast-2:863518440691:app/GCM/woncheon-android" \
  --region ap-northeast-2 --profile dongik2 \
  --query 'length(Endpoints[?Attributes.Enabled==`true`])' --output text | xargs -I{} echo "  Active: {}"
```

---

## 테스트 푸시 발송

### iOS 전체

```bash
./send-test-push-all.sh
```

iOS Production(APNS) 엔드포인트 전체에 테스트 메시지 발송.

### Android 전체

```bash
./send-test-push-android.sh
```

Android(GCM/FCM) 엔드포인트 전체에 테스트 메시지 발송.

### 전체 (iOS + Android) — broadcast

```bash
AWS_PROFILE=dongik2 node scripts/broadcast-once.mjs
```

DynamoDB GSI3 (ALL_DEVICES) → BatchGet → SNS publish 패턴.
모든 등록 디바이스에 커스텀 메시지 발송. 메시지 변경은 스크립트 내 `TITLE`, `BODY` 상수 수정.

### 단일 엔드포인트 테스트 (iOS)

```bash
aws sns publish \
  --target-arn "arn:aws:sns:ap-northeast-2:863518440691:endpoint/APNS/woncheon-ios/<ENDPOINT_ID>" \
  --message '{"default":"테스트","APNS":"{\"aps\":{\"alert\":{\"title\":\"원천청년부\",\"body\":\"테스트 푸시입니다\"},\"sound\":\"default\"}}"}' \
  --message-structure json \
  --region ap-northeast-2 --profile dongik2
```

### 단일 엔드포인트 테스트 (Android)

```bash
aws sns publish \
  --target-arn "arn:aws:sns:ap-northeast-2:863518440691:endpoint/GCM/woncheon-android/<ENDPOINT_ID>" \
  --message '{"default":"테스트","GCM":"{\"notification\":{\"title\":\"원천청년부\",\"body\":\"테스트 푸시입니다\"},\"data\":{\"screen\":\"prayer_list\"}}"}' \
  --message-structure json \
  --region ap-northeast-2 --profile dongik2
```

---

## 스크립트 목록

| 파일 | 용도 |
|------|------|
| `send-test-push-all.sh` | iOS(APNS) 전체 endpoint에 테스트 푸시 |
| `send-test-push-android.sh` | Android(FCM) 전체 endpoint에 테스트 푸시 |
| `broadcast-once.mjs` | DynamoDB 기반 전체 broadcast (iOS+Android 통합) |

---

## 자동 발송 (EventBridge)

주간 중보기도 알림은 Lambda `sendWeeklyNotification` 이 자동 실행:

- 화요일 11:00 KST (`cron(0 2 ? * TUE *)`)
- 금요일 20:00 KST (`cron(0 11 ? * FRI *)`)

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| Enabled: false | 토큰 만료 or 앱 삭제 | 사용자가 재로그인하면 자동 갱신 |
| 알림 미수신 (iOS) | Background refresh 꺼짐 | 설정 > 일반 > 백그라운드 앱 새로고침 |
| 알림 미수신 (Android) | 채널 중요도 낮음 | `prayer_high` 채널 (IMPORTANCE_HIGH) 사용 확인 |
| 0/N 발송 성공 | GSI3 KEYS_ONLY bug | `broadcast-once.mjs` 패턴 (GSI3→BatchGet) 사용 |
