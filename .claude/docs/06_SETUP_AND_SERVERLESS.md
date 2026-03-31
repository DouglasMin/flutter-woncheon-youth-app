# 원천청년부 앱 — 백엔드 세팅 가이드 & serverless.yml 초안

## 1. 프로젝트 초기화

```bash
mkdir woncheon-backend && cd woncheon-backend
pnpm init
pnpm add -D serverless serverless-offline esbuild serverless-esbuild
pnpm add @aws-sdk/client-dynamodb @aws-sdk/lib-dynamodb
pnpm add @aws-sdk/client-sns
pnpm add bcryptjs jsonwebtoken ulid
pnpm add -D @types/bcryptjs @types/jsonwebtoken @types/node typescript
```

---

## 2. serverless.yml

```yaml
service: woncheon-backend

frameworkVersion: "4"

provider:
  name: aws
  runtime: nodejs22.x
  region: ap-northeast-2
  stage: ${opt:stage, 'dev'}
  environment:
    TABLE_NAME: woncheon-${sls:stage}
    JWT_SECRET: ${ssm:/woncheon/${sls:stage}/jwt-secret}
    JWT_REFRESH_SECRET: ${ssm:/woncheon/${sls:stage}/jwt-refresh-secret}
    SNS_IOS_PLATFORM_ARN: ${ssm:/woncheon/${sls:stage}/sns-ios-arn}
    SNS_ANDROID_PLATFORM_ARN: ${ssm:/woncheon/${sls:stage}/sns-android-arn}
  iam:
    role:
      statements:
        - Effect: Allow
          Action:
            - dynamodb:GetItem
            - dynamodb:PutItem
            - dynamodb:UpdateItem
            - dynamodb:DeleteItem
            - dynamodb:Query
            - dynamodb:Scan
          Resource:
            - arn:aws:dynamodb:ap-northeast-2:*:table/woncheon-${sls:stage}
            - arn:aws:dynamodb:ap-northeast-2:*:table/woncheon-${sls:stage}/index/*
        - Effect: Allow
          Action:
            - sns:Publish
            - sns:CreatePlatformEndpoint
          Resource: "*"

plugins:
  - serverless-esbuild
  - serverless-offline

custom:
  esbuild:
    bundle: true
    minify: false
    sourcemap: true
    target: node22
    platform: node

functions:
  # ── Authorizer ──────────────────────────────
  jwtAuthorizer:
    handler: src/functions/auth/authorizer.handler

  # ── Auth ────────────────────────────────────
  login:
    handler: src/functions/auth/login.handler
    events:
      - http:
          path: /auth/login
          method: post
          cors: true

  changePassword:
    handler: src/functions/auth/changePassword.handler
    events:
      - http:
          path: /auth/change-password
          method: post
          cors: true
          authorizer:
            name: jwtAuthorizer
            resultTtlInSeconds: 0

  refresh:
    handler: src/functions/auth/refresh.handler
    events:
      - http:
          path: /auth/refresh
          method: post
          cors: true

  registerDeviceToken:
    handler: src/functions/auth/deviceToken.handler
    events:
      - http:
          path: /auth/device-token
          method: post
          cors: true
          authorizer:
            name: jwtAuthorizer
            resultTtlInSeconds: 0

  # ── Prayer ──────────────────────────────────
  listPrayers:
    handler: src/functions/prayer/list.handler
    events:
      - http:
          path: /prayers
          method: get
          cors: true
          authorizer:
            name: jwtAuthorizer
            resultTtlInSeconds: 0

  createPrayer:
    handler: src/functions/prayer/create.handler
    events:
      - http:
          path: /prayers
          method: post
          cors: true
          authorizer:
            name: jwtAuthorizer
            resultTtlInSeconds: 0

  getPrayer:
    handler: src/functions/prayer/get.handler
    events:
      - http:
          path: /prayers/{prayerId}
          method: get
          cors: true
          authorizer:
            name: jwtAuthorizer
            resultTtlInSeconds: 0

  deletePrayer:
    handler: src/functions/prayer/delete.handler
    events:
      - http:
          path: /prayers/{prayerId}
          method: delete
          cors: true
          authorizer:
            name: jwtAuthorizer
            resultTtlInSeconds: 0

  # ── Notification ────────────────────────────
  sendWeeklyNotification:
    handler: src/functions/notification/sendWeekly.handler
    events:
      - schedule:
          rate: cron(0 11 ? * SAT *)   # 매주 토요일 KST 20:00
          enabled: true

resources:
  Resources:
    WoncheonTable:
      Type: AWS::DynamoDB::Table
      Properties:
        TableName: woncheon-${sls:stage}
        BillingMode: PAY_PER_REQUEST
        AttributeDefinitions:
          - AttributeName: PK
            AttributeType: S
          - AttributeName: SK
            AttributeType: S
          - AttributeName: GSI1PK
            AttributeType: S
          - AttributeName: GSI1SK
            AttributeType: S
          - AttributeName: GSI2PK
            AttributeType: S
          - AttributeName: GSI2SK
            AttributeType: S
          - AttributeName: GSI3PK
            AttributeType: S
        KeySchema:
          - AttributeName: PK
            KeyType: HASH
          - AttributeName: SK
            KeyType: RANGE
        GlobalSecondaryIndexes:
          - IndexName: GSI1
            KeySchema:
              - AttributeName: GSI1PK
                KeyType: HASH
              - AttributeName: GSI1SK
                KeyType: RANGE
            Projection:
              ProjectionType: ALL
          - IndexName: GSI2
            KeySchema:
              - AttributeName: GSI2PK
                KeyType: HASH
              - AttributeName: GSI2SK
                KeyType: RANGE
            Projection:
              ProjectionType: ALL
          - IndexName: GSI3
            KeySchema:
              - AttributeName: GSI3PK
                KeyType: HASH
            Projection:
              ProjectionType: ALL
        TimeToLiveSpecification:
          AttributeName: expiresAt
          Enabled: true
```

---

## 3. SSM Parameter 등록 (최초 1회)

```bash
# JWT Secret
aws ssm put-parameter \
  --name "/woncheon/dev/jwt-secret" \
  --value "your-strong-secret-key" \
  --type SecureString \
  --region ap-northeast-2

aws ssm put-parameter \
  --name "/woncheon/dev/jwt-refresh-secret" \
  --value "your-strong-refresh-secret" \
  --type SecureString \
  --region ap-northeast-2

# SNS Platform Application ARN (FCM, APNs 생성 후)
aws ssm put-parameter \
  --name "/woncheon/dev/sns-ios-arn" \
  --value "arn:aws:sns:ap-northeast-2:..." \
  --type String \
  --region ap-northeast-2

aws ssm put-parameter \
  --name "/woncheon/dev/sns-android-arn" \
  --value "arn:aws:sns:ap-northeast-2:..." \
  --type String \
  --region ap-northeast-2
```

---

## 4. SNS Platform Application 생성 (최초 1회)

### Android (FCM)
```bash
aws sns create-platform-application \
  --name woncheon-android-dev \
  --platform GCM \
  --attributes PlatformCredential={FCM_SERVER_KEY} \
  --region ap-northeast-2
```

### iOS (APNs)
```bash
aws sns create-platform-application \
  --name woncheon-ios-dev \
  --platform APNS_SANDBOX \
  --attributes \
    PlatformCredential={APNS_PRIVATE_KEY} \
    PlatformPrincipal={APNS_CERTIFICATE} \
  --region ap-northeast-2
```

> iOS 배포 시 `APNS_SANDBOX` → `APNS`로 변경

---

## 5. 배포 명령어

```bash
# dev 배포
pnpm sls deploy --stage dev

# prod 배포
pnpm sls deploy --stage prod

# 로컬 개발
pnpm sls offline --stage dev
```

---

## 6. Flutter pubspec.yaml 주요 패키지

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  dio: ^5.0.0
  
  # 상태관리
  flutter_riverpod: ^2.0.0
  
  # 로컬 저장소 (토큰)
  flutter_secure_storage: ^9.0.0
  
  # 푸시 알림
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  
  # 라우팅
  go_router: ^14.0.0
  
  # 유틸
  intl: ^0.19.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

---

## 7. 회원 마이그레이션 스크립트 개요

```typescript
// scripts/migrate-members.ts
// Google Sheets export CSV → DynamoDB 삽입

import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import { ulid } from 'ulid';
import * as bcrypt from 'bcryptjs';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

const DEFAULT_PASSWORD = 'woncheon2025';
const TABLE_NAME = 'woncheon-dev';

async function migrate() {
  const csv = readFileSync('./members.csv', 'utf-8');
  const records = parse(csv, { columns: true });

  for (const record of records) {
    const memberId = ulid();
    const name = record['이름'].trim();
    const passwordHash = await bcrypt.hash(DEFAULT_PASSWORD, 10);

    // Member 레코드
    await docClient.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        PK: `MEMBER#${memberId}`,
        SK: '#META',
        GSI1PK: `NAME#${name}`,
        GSI1SK: '#META',
        memberId,
        name,
        passwordHash,
        isFirstLogin: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
    }));

    console.log(`✅ ${name} 등록 완료`);
  }
}

migrate();
```

실행:
```bash
npx ts-node scripts/migrate-members.ts
```
