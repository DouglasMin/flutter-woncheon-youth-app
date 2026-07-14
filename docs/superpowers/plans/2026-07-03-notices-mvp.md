# Notices MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal 공지사항 feature where admins can create/manage notices and app users can read published notices.

**Architecture:** Store notices in the existing DynamoDB single table with `NOTICE#{noticeId}` as the primary item and `GSI2PK = NOTICE_LIST` for latest-first app/admin listing. The Flutter app gets read-only JWT-protected public notice APIs from the Serverless backend; the Next.js admin panel uses its existing `/api/admin/*` routes to write and manage the same DynamoDB items. Notice push notifications are sent by a DynamoDB Stream Lambda only when a notice enters `published` for the first time and has no `notifiedAt`, so edits and re-publishes do not fan out duplicate SNS messages.

**Tech Stack:** Flutter/Riverpod/GoRouter/Dio, Serverless Framework v4, AWS Lambda Node.js 22/TypeScript, DynamoDB DocumentClient + Streams, AWS SNS, Next.js admin panel, shadcn-style UI components, Vitest, Flutter widget tests.

---

## Scope Decision

Implement now:
- Admin can list, create, edit, publish/unpublish, and delete notices.
- App can open the existing Home `공지사항` tile.
- App can list published notices.
- App can open notice detail.
- App shows consistent loading/error/empty states.
- First-time publish sends one SNS push notification to all registered devices.

Do not implement now:
- Rich text editor.
- Attachments/images.
- Per-user read receipts.
- Notice comments/reactions.
- Manual "send notification again" admin action.
- Audience targeting; v1 sends to all registered devices.

This keeps the feature small enough to ship safely while avoiding duplicate push behavior.

## DynamoDB Shape

Notice item:

```ts
{
  PK: `NOTICE#${noticeId}`,
  SK: "#META",
  GSI2PK: "NOTICE_LIST",
  GSI2SK: `${publishedAtOrCreatedAt}#${noticeId}`,
  noticeId: string,
  title: string,
  content: string,
  status: "draft" | "published",
  pinned: boolean,
  createdAt: string,
  updatedAt: string,
  publishedAt?: string,
  notifiedAt?: string,
  notificationStatus?: "pending" | "sending" | "sent" | "partial_fail" | "failed",
  notificationRecipientCount?: number,
  notificationSuccessCount?: number,
  notificationFailureCount?: number
}
```

App list ordering:
- Query `GSI2PK = NOTICE_LIST`.
- `ScanIndexForward: false`.
- Return only `status = "published"`.
- Pinned ordering is not special in v1. `pinned` is stored now but only displayed as a badge. This avoids extra indexes and keeps writes simple.

Push notification policy:
- Draft create/update never sends push.
- `draft -> published` sends one push if `notifiedAt` is missing.
- Published create sends one push if `notifiedAt` is missing.
- Published edit never sends push.
- `published -> draft` never sends push.
- Re-publish after a prior notification does not send push because `notifiedAt` remains set.
- The stream worker claims delivery by setting `notificationStatus = "sending"` before publishing, then records `notifiedAt` and delivery counts after `Promise.allSettled`.

---

## File Structure

### Backend

- Create `woncheon-backend/src/types/notice.ts`
  - Shared TypeScript notice types.
- Create `woncheon-backend/src/functions/notice/list.ts`
  - App API: `GET /notices`.
- Create `woncheon-backend/src/functions/notice/get.ts`
  - App API: `GET /notices/{noticeId}`.
- Create `woncheon-backend/src/libs/device-notifications.ts`
  - Shared helper to query all registered SNS endpoints and publish a notice push.
- Create `woncheon-backend/src/functions/notice/sendNotification.ts`
  - DynamoDB Stream worker that sends exactly-once best-effort notice notifications.
- Modify `woncheon-backend/serverless.yml`
  - Add two JWT-protected app endpoints.
  - Enable DynamoDB Streams on the existing `woncheon-${stage}` table.
  - Add one stream-triggered Lambda for notice push fan-out.
- Create `woncheon-backend/tests/notice/list.test.ts`
  - Unit tests for response mapping/filtering helpers.
- Create `woncheon-backend/tests/notice/notification-policy.test.ts`
  - Unit tests for first-publish-only push policy.

### Admin

- Create `woncheon-admin/src/app/api/admin/notices/route.ts`
  - Admin `GET`, `POST`, `PUT`, `DELETE`.
- Create `woncheon-admin/src/app/(admin)/notices/page.tsx`
  - Admin notice management screen.
- Modify `woncheon-admin/src/components/layout/sidebar.tsx`
  - Add 공지사항 nav item.

### Flutter

- Create `lib/features/notice/domain/notice_model.dart`
  - `NoticeItem`, `NoticeDetail`, `NoticeListResponse`.
- Create generated files after build runner:
  - `lib/features/notice/domain/notice_model.freezed.dart`
  - `lib/features/notice/domain/notice_model.g.dart`
- Create `lib/features/notice/data/notice_repository.dart`
  - Dio API calls.
- Create `lib/features/notice/presentation/notice_providers.dart`
  - Riverpod list/detail providers.
- Create `lib/features/notice/presentation/notice_list_page.dart`
  - Published notice list.
- Create `lib/features/notice/presentation/notice_detail_page.dart`
  - Notice detail.
- Modify `lib/core/api/endpoints.dart`
  - Add `/notices`.
- Modify `lib/core/router/app_router.dart`
  - Add list/detail routes under root navigator.
- Modify `lib/features/home/presentation/home_page.dart`
  - Enable the `공지사항` tile.

### Tests

- Create `test/features/notice/presentation/notice_list_page_test.dart`
  - Empty state and visible card test.
- Create `test/features/notice/domain/notice_model_test.dart`
  - JSON parsing test.

---

## Task 1: Backend Notice Types and Mapping Helpers

**Files:**
- Create: `woncheon-backend/src/types/notice.ts`
- Create: `woncheon-backend/tests/notice/list.test.ts`
- Create: `woncheon-backend/tests/notice/notification-policy.test.ts`

- [ ] **Step 1: Create the failing backend test**

Create `woncheon-backend/tests/notice/list.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { toNoticeListItem } from "../../src/types/notice.js";

describe("notice mapping", () => {
  it("maps a DynamoDB notice item to the app list shape", () => {
    const item = {
      noticeId: "NOTICE01",
      title: "이번 주 청년부 안내",
      content: "금요 성령집회 후 청년부 모임이 있습니다.",
      status: "published",
      pinned: true,
      createdAt: "2026-07-03T01:00:00.000Z",
      updatedAt: "2026-07-03T01:10:00.000Z",
      publishedAt: "2026-07-03T01:20:00.000Z",
    };

    expect(toNoticeListItem(item)).toEqual({
      noticeId: "NOTICE01",
      title: "이번 주 청년부 안내",
      contentPreview: "금요 성령집회 후 청년부 모임이 있습니다.",
      pinned: true,
      publishedAt: "2026-07-03T01:20:00.000Z",
    });
  });

  it("truncates long content previews", () => {
    const longContent = "가".repeat(160);
    const item = {
      noticeId: "NOTICE02",
      title: "긴 공지",
      content: longContent,
      status: "published",
      pinned: false,
      createdAt: "2026-07-03T01:00:00.000Z",
      updatedAt: "2026-07-03T01:10:00.000Z",
      publishedAt: "2026-07-03T01:20:00.000Z",
    };

    expect(toNoticeListItem(item).contentPreview).toBe(`${"가".repeat(120)}...`);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
cd woncheon-backend
pnpm test tests/notice/list.test.ts
```

Expected:

```text
FAIL tests/notice/list.test.ts
Cannot find module '../../src/types/notice.js'
```

- [ ] **Step 3: Create the failing notification policy test**

Create `woncheon-backend/tests/notice/notification-policy.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { shouldSendNoticeNotification } from "../../src/types/notice.js";

describe("notice notification policy", () => {
  it("sends when a draft is first published", () => {
    expect(
      shouldSendNoticeNotification(
        { status: "draft" },
        { status: "published" },
      ),
    ).toBe(true);
  });

  it("does not send when a published notice is edited", () => {
    expect(
      shouldSendNoticeNotification(
        { status: "published" },
        { status: "published" },
      ),
    ).toBe(false);
  });

  it("does not send when a previously notified notice is republished", () => {
    expect(
      shouldSendNoticeNotification(
        { status: "draft", notifiedAt: "2026-07-03T01:00:00.000Z" },
        { status: "published", notifiedAt: "2026-07-03T01:00:00.000Z" },
      ),
    ).toBe(false);
  });

  it("sends for a newly created published notice with no notifiedAt", () => {
    expect(
      shouldSendNoticeNotification(undefined, { status: "published" }),
    ).toBe(true);
  });
});
```

- [ ] **Step 4: Run the policy test to verify it fails**

Run:

```bash
cd woncheon-backend
pnpm test tests/notice/notification-policy.test.ts
```

Expected:

```text
FAIL tests/notice/notification-policy.test.ts
No matching export for import "shouldSendNoticeNotification"
```

- [ ] **Step 5: Implement notice types, mapper, and notification policy**

Create `woncheon-backend/src/types/notice.ts`:

```ts
export type NoticeStatus = "draft" | "published";

export interface NoticeRecord {
  PK?: string;
  SK?: string;
  GSI2PK?: string;
  GSI2SK?: string;
  noticeId: string;
  title: string;
  content: string;
  status: NoticeStatus;
  pinned: boolean;
  createdAt: string;
  updatedAt: string;
  publishedAt?: string;
  notifiedAt?: string;
  notificationStatus?: "pending" | "sending" | "sent" | "partial_fail" | "failed";
  notificationRecipientCount?: number;
  notificationSuccessCount?: number;
  notificationFailureCount?: number;
}

export interface NoticeListItem {
  noticeId: string;
  title: string;
  contentPreview: string;
  pinned: boolean;
  publishedAt: string;
}

export interface NoticeDetail {
  noticeId: string;
  title: string;
  content: string;
  pinned: boolean;
  publishedAt: string;
}

export function makeNoticePreview(content: string): string {
  const trimmed = content.trim();
  return trimmed.length > 120 ? `${trimmed.substring(0, 120)}...` : trimmed;
}

export function toNoticeListItem(item: NoticeRecord): NoticeListItem {
  return {
    noticeId: item.noticeId,
    title: item.title,
    contentPreview: makeNoticePreview(item.content),
    pinned: item.pinned,
    publishedAt: item.publishedAt ?? item.createdAt,
  };
}

export function toNoticeDetail(item: NoticeRecord): NoticeDetail {
  return {
    noticeId: item.noticeId,
    title: item.title,
    content: item.content,
    pinned: item.pinned,
    publishedAt: item.publishedAt ?? item.createdAt,
  };
}

export function shouldSendNoticeNotification(
  previous: Pick<NoticeRecord, "status" | "notifiedAt"> | undefined,
  next: Pick<NoticeRecord, "status" | "notifiedAt">,
): boolean {
  if (next.status !== "published") return false;
  if (next.notifiedAt) return false;
  return previous?.status !== "published";
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run:

```bash
cd woncheon-backend
pnpm test tests/notice/list.test.ts tests/notice/notification-policy.test.ts
```

Expected:

```text
PASS tests/notice/list.test.ts
PASS tests/notice/notification-policy.test.ts
```

- [ ] **Step 7: Commit**

```bash
git add woncheon-backend/src/types/notice.ts woncheon-backend/tests/notice/list.test.ts woncheon-backend/tests/notice/notification-policy.test.ts
git commit -m "feat: add notice backend types"
```

---

## Task 2: Backend App Notice APIs

**Files:**
- Create: `woncheon-backend/src/functions/notice/list.ts`
- Create: `woncheon-backend/src/functions/notice/get.ts`
- Modify: `woncheon-backend/serverless.yml`

- [ ] **Step 1: Create list endpoint implementation**

Create `woncheon-backend/src/functions/notice/list.ts`:

```ts
import type { APIGatewayProxyHandler } from "aws-lambda";
import { QueryCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "../../libs/dynamo.js";
import { success } from "../../libs/response.js";
import type { NoticeRecord } from "../../types/notice.js";
import { toNoticeListItem } from "../../types/notice.js";

const VALID_CURSOR_KEYS = new Set(["PK", "SK", "GSI2PK", "GSI2SK"]);

function parseCursor(cursorParam: string | undefined): Record<string, unknown> | undefined {
  if (!cursorParam) return undefined;
  try {
    const parsed = JSON.parse(Buffer.from(cursorParam, "base64").toString("utf-8")) as unknown;
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) return undefined;
    const obj = parsed as Record<string, unknown>;
    const keys = Object.keys(obj);
    if (keys.length !== VALID_CURSOR_KEYS.size) return undefined;
    for (const key of keys) {
      if (!VALID_CURSOR_KEYS.has(key)) return undefined;
      if (typeof obj[key] !== "string") return undefined;
    }
    return obj;
  } catch {
    return undefined;
  }
}

export const handler: APIGatewayProxyHandler = async (event) => {
  const limit = Math.min(Number(event.queryStringParameters?.limit ?? 20), 50);
  const exclusiveStartKey = parseCursor(event.queryStringParameters?.cursor ?? undefined);

  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: "GSI2",
      KeyConditionExpression: "GSI2PK = :pk",
      FilterExpression: "#status = :published",
      ExpressionAttributeNames: { "#status": "status" },
      ExpressionAttributeValues: {
        ":pk": "NOTICE_LIST",
        ":published": "published",
      },
      ScanIndexForward: false,
      Limit: limit,
      ExclusiveStartKey: exclusiveStartKey,
    }),
  );

  const items = ((result.Items ?? []) as NoticeRecord[]).map(toNoticeListItem);
  const nextCursor = result.LastEvaluatedKey
    ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString("base64")
    : null;

  return success({
    items,
    nextCursor,
    hasMore: Boolean(nextCursor),
  });
};
```

- [ ] **Step 2: Create detail endpoint implementation**

Create `woncheon-backend/src/functions/notice/get.ts`:

```ts
import type { APIGatewayProxyHandler } from "aws-lambda";
import { GetCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "../../libs/dynamo.js";
import { error, success } from "../../libs/response.js";
import type { NoticeRecord } from "../../types/notice.js";
import { toNoticeDetail } from "../../types/notice.js";

export const handler: APIGatewayProxyHandler = async (event) => {
  const noticeId = event.pathParameters?.noticeId;
  if (!noticeId) {
    return error("VALIDATION_ERROR", "noticeId가 필요합니다.", 400);
  }

  const result = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `NOTICE#${noticeId}`, SK: "#META" },
    }),
  );

  const item = result.Item as NoticeRecord | undefined;
  if (!item || item.status !== "published") {
    return error("NOT_FOUND", "공지사항을 찾을 수 없습니다.", 404);
  }

  return success(toNoticeDetail(item));
};
```

- [ ] **Step 3: Register endpoints in Serverless**

Modify `woncheon-backend/serverless.yml` inside `functions:` after the prayer endpoints:

```yaml
  # ── Notices ─────────────────────────────────
  listNotices:
    handler: src/functions/notice/list.handler
    events:
      - http:
          path: /notices
          method: get
          cors: true
          authorizer:
            name: jwtAuthorizer
            resultTtlInSeconds: 0
            identitySource: method.request.header.Authorization
            type: request

  getNotice:
    handler: src/functions/notice/get.handler
    events:
      - http:
          path: /notices/{noticeId}
          method: get
          cors: true
          authorizer:
            name: jwtAuthorizer
            resultTtlInSeconds: 0
            identitySource: method.request.header.Authorization
            type: request
```

- [ ] **Step 4: Type-check/package backend**

Run:

```bash
cd woncheon-backend
pnpm test
pnpm sls package --stage dev
```

Expected:

```text
Test Files ... passed
Service packaged
```

- [ ] **Step 5: Commit**

```bash
git add woncheon-backend/src/functions/notice/list.ts woncheon-backend/src/functions/notice/get.ts woncheon-backend/serverless.yml
git commit -m "feat: add app notice api"
```

---

## Task 3: Backend Notice Push Notification Worker

**Files:**
- Create: `woncheon-backend/src/libs/device-notifications.ts`
- Create: `woncheon-backend/src/functions/notice/sendNotification.ts`
- Modify: `woncheon-backend/serverless.yml`

**Infrastructure changes:**
- Enable DynamoDB Streams on the existing `woncheon-${stage}` table with `StreamViewType: NEW_AND_OLD_IMAGES`.
- Add one Lambda function: `sendNoticeNotification`.
- Add one DynamoDB Stream event source mapping from `WoncheonTable.StreamArn` to `sendNoticeNotification`.
- No new DynamoDB table, no new GSI, no new SNS Platform Application.

- [ ] **Step 1: Create shared device notification helper**

Create `woncheon-backend/src/libs/device-notifications.ts`:

```ts
import { BatchGetCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "./dynamo.js";
import { publishToEndpoint } from "./sns.js";

export interface NotificationFanoutResult {
  total: number;
  successCount: number;
  failureCount: number;
}

export async function queryAllDeviceEndpoints(): Promise<string[]> {
  const keys: Array<{ PK: string; SK: string }> = [];
  let lastKey: Record<string, unknown> | undefined;

  do {
    const result = await docClient.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        IndexName: "GSI3",
        KeyConditionExpression: "GSI3PK = :pk",
        ExpressionAttributeValues: { ":pk": "ALL_DEVICES" },
        ExclusiveStartKey: lastKey,
      }),
    );

    for (const item of result.Items ?? []) {
      if (typeof item.PK === "string" && typeof item.SK === "string") {
        keys.push({ PK: item.PK, SK: item.SK });
      }
    }
    lastKey = result.LastEvaluatedKey;
  } while (lastKey);

  const endpoints: string[] = [];
  for (let i = 0; i < keys.length; i += 100) {
    const batch = await docClient.send(
      new BatchGetCommand({
        RequestItems: { [TABLE_NAME]: { Keys: keys.slice(i, i + 100) } },
      }),
    );

    for (const device of batch.Responses?.[TABLE_NAME] ?? []) {
      if (typeof device.snsEndpoint === "string" && device.snsEndpoint.length > 0) {
        endpoints.push(device.snsEndpoint);
      }
    }
  }

  return endpoints;
}

export async function publishNoticeToAllDevices(params: {
  noticeId: string;
  title: string;
  body: string;
}): Promise<NotificationFanoutResult> {
  const endpoints = await queryAllDeviceEndpoints();
  const results = await Promise.allSettled(
    endpoints.map((endpoint) =>
      publishToEndpoint(endpoint, "원천청년부 공지", params.title, {
        screen: "notice_detail",
        noticeId: params.noticeId,
      }),
    ),
  );

  const successCount = results.filter((result) => result.status === "fulfilled").length;
  return {
    total: endpoints.length,
    successCount,
    failureCount: endpoints.length - successCount,
  };
}
```

- [ ] **Step 2: Create stream worker**

Create `woncheon-backend/src/functions/notice/sendNotification.ts`:

```ts
import type { DynamoDBStreamHandler } from "aws-lambda";
import { UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "../../libs/dynamo.js";
import { publishNoticeToAllDevices } from "../../libs/device-notifications.js";
import { makeNoticePreview, shouldSendNoticeNotification } from "../../types/notice.js";

type StreamImage = Record<string, { S?: string; BOOL?: boolean; N?: string }>;

function readString(image: StreamImage | undefined, key: string): string | undefined {
  return image?.[key]?.S;
}

function noticeFromImage(image: StreamImage | undefined) {
  const noticeId = readString(image, "noticeId");
  const status = readString(image, "status");
  if (!noticeId || (status !== "draft" && status !== "published")) return undefined;

  return {
    noticeId,
    title: readString(image, "title") ?? "",
    content: readString(image, "content") ?? "",
    status,
    notifiedAt: readString(image, "notifiedAt"),
  };
}

async function claimNotification(noticeId: string): Promise<boolean> {
  try {
    await docClient.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: { PK: `NOTICE#${noticeId}`, SK: "#META" },
        UpdateExpression:
          "SET notificationStatus = :sending, notificationClaimedAt = :now",
        ConditionExpression:
          "#status = :published AND attribute_not_exists(notifiedAt) AND (attribute_not_exists(notificationStatus) OR notificationStatus = :pending)",
        ExpressionAttributeNames: { "#status": "status" },
        ExpressionAttributeValues: {
          ":published": "published",
          ":pending": "pending",
          ":sending": "sending",
          ":now": new Date().toISOString(),
        },
      }),
    );
    return true;
  } catch {
    return false;
  }
}

export const handler: DynamoDBStreamHandler = async (event) => {
  for (const record of event.Records) {
    const previous = noticeFromImage(record.dynamodb?.OldImage as StreamImage | undefined);
    const next = noticeFromImage(record.dynamodb?.NewImage as StreamImage | undefined);
    if (!next || !shouldSendNoticeNotification(previous, next)) continue;

    const claimed = await claimNotification(next.noticeId);
    if (!claimed) continue;

    const result = await publishNoticeToAllDevices({
      noticeId: next.noticeId,
      title: next.title,
      body: makeNoticePreview(next.content),
    });

    const notificationStatus =
      result.failureCount === 0 ? "sent" : result.successCount > 0 ? "partial_fail" : "failed";

    await docClient.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: { PK: `NOTICE#${next.noticeId}`, SK: "#META" },
        UpdateExpression:
          "SET notifiedAt = :now, notificationStatus = :status, notificationRecipientCount = :total, notificationSuccessCount = :success, notificationFailureCount = :failure",
        ExpressionAttributeValues: {
          ":now": new Date().toISOString(),
          ":status": notificationStatus,
          ":total": result.total,
          ":success": result.successCount,
          ":failure": result.failureCount,
        },
      }),
    );
  }
};
```

- [ ] **Step 3: Register stream worker in Serverless**

Modify `woncheon-backend/serverless.yml` inside `functions:`:

```yaml
  sendNoticeNotification:
    handler: src/functions/notice/sendNotification.handler
    events:
      - stream:
          type: dynamodb
          arn:
            Fn::GetAtt:
              - WoncheonTable
              - StreamArn
          batchSize: 10
          startingPosition: LATEST
          maximumRetryAttempts: 0
```

Modify `resources.Resources.WoncheonTable.Properties`:

```yaml
        StreamSpecification:
          StreamViewType: NEW_AND_OLD_IMAGES
```

- [ ] **Step 4: Type-check/package backend**

Run:

```bash
cd woncheon-backend
pnpm test
pnpm sls package --stage dev
```

Expected:

```text
Test Files ... passed
Service packaged
```

- [ ] **Step 5: Commit**

```bash
git add woncheon-backend/src/libs/device-notifications.ts woncheon-backend/src/functions/notice/sendNotification.ts woncheon-backend/serverless.yml
git commit -m "feat: send notice push on first publish"
```

---

## Task 4: Admin Notice API

**Files:**
- Create: `woncheon-admin/src/app/api/admin/notices/route.ts`

- [ ] **Step 1: Create admin API route**

Create `woncheon-admin/src/app/api/admin/notices/route.ts`:

```ts
import { NextResponse } from "next/server";
import { DeleteCommand, GetCommand, PutCommand, QueryCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { ulid } from "ulid";
import { docClient, TABLE_NAME } from "@/lib/db/dynamo";

type NoticeStatus = "draft" | "published";

interface NoticeInput {
  noticeId?: string;
  title?: string;
  content?: string;
  status?: NoticeStatus;
  pinned?: boolean;
}

function validateNoticeInput(body: NoticeInput): string | null {
  if (!body.title || body.title.trim().length === 0) return "제목을 입력해주세요.";
  if (body.title.length > 80) return "제목은 80자 이내로 입력해주세요.";
  if (!body.content || body.content.trim().length === 0) return "내용을 입력해주세요.";
  if (body.content.length > 3000) return "내용은 3000자 이내로 입력해주세요.";
  if (body.status && !["draft", "published"].includes(body.status)) {
    return "status는 draft 또는 published여야 합니다.";
  }
  return null;
}

export async function GET() {
  try {
    const result = await docClient.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        IndexName: "GSI2",
        KeyConditionExpression: "GSI2PK = :pk",
        ExpressionAttributeValues: { ":pk": "NOTICE_LIST" },
        ScanIndexForward: false,
        Limit: 100,
      }),
    );

    const notices = (result.Items ?? []).map((item) => ({
      noticeId: item.noticeId,
      title: item.title,
      content: item.content,
      status: item.status,
      pinned: Boolean(item.pinned),
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      publishedAt: item.publishedAt ?? null,
      notifiedAt: item.notifiedAt ?? null,
      notificationStatus: item.notificationStatus ?? null,
      notificationRecipientCount: item.notificationRecipientCount ?? 0,
      notificationSuccessCount: item.notificationSuccessCount ?? 0,
      notificationFailureCount: item.notificationFailureCount ?? 0,
    }));

    return NextResponse.json({ notices });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "공지 목록을 불러올 수 없습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as NoticeInput;
    const validationError = validateNoticeInput(body);
    if (validationError) {
      return NextResponse.json({ error: validationError }, { status: 400 });
    }

    const noticeId = ulid();
    const now = new Date().toISOString();
    const status = body.status ?? "draft";
    const publishedAt = status === "published" ? now : undefined;
    const sortAt = publishedAt ?? now;
    const notificationStatus = status === "published" ? "pending" : undefined;

    await docClient.send(
      new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `NOTICE#${noticeId}`,
          SK: "#META",
          GSI2PK: "NOTICE_LIST",
          GSI2SK: `${sortAt}#${noticeId}`,
          noticeId,
          title: body.title!.trim(),
          content: body.content!.trim(),
          status,
          pinned: body.pinned ?? false,
          createdAt: now,
          updatedAt: now,
          publishedAt,
          notificationStatus,
        },
      }),
    );

    return NextResponse.json({ success: true, noticeId }, { status: 201 });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "공지 생성에 실패했습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  try {
    const body = (await request.json()) as NoticeInput;
    if (!body.noticeId) {
      return NextResponse.json({ error: "noticeId가 필요합니다." }, { status: 400 });
    }
    const validationError = validateNoticeInput(body);
    if (validationError) {
      return NextResponse.json({ error: validationError }, { status: 400 });
    }

    const existing = await docClient.send(
      new GetCommand({
        TableName: TABLE_NAME,
        Key: { PK: `NOTICE#${body.noticeId}`, SK: "#META" },
      }),
    );

    if (!existing.Item) {
      return NextResponse.json({ error: "존재하지 않는 공지입니다." }, { status: 404 });
    }

    const now = new Date().toISOString();
    const nextStatus = body.status ?? "draft";
    const previousStatus = existing.Item.status as NoticeStatus;
    const previousNotifiedAt = existing.Item.notifiedAt as string | undefined;
    const previousPublishedAt = existing.Item.publishedAt as string | undefined;
    const nextPublishedAt =
      nextStatus === "published" ? previousPublishedAt ?? now : undefined;
    const sortAt = nextPublishedAt ?? (existing.Item.createdAt as string) ?? now;
    const shouldQueueNotification =
      previousStatus !== "published" && nextStatus === "published" && !previousNotifiedAt;

    const setExpressions = [
      "GSI2SK = :gsi2sk",
      "title = :title",
      "content = :content",
      "#status = :status",
      "pinned = :pinned",
      "updatedAt = :updatedAt",
      "publishedAt = :publishedAt",
    ];
    const expressionAttributeValues: Record<string, unknown> = {
      ":gsi2sk": `${sortAt}#${body.noticeId}`,
      ":title": body.title!.trim(),
      ":content": body.content!.trim(),
      ":status": nextStatus,
      ":pinned": body.pinned ?? false,
      ":updatedAt": now,
      ":publishedAt": nextPublishedAt,
    };
    if (shouldQueueNotification) {
      setExpressions.push("notificationStatus = :notificationStatus");
      expressionAttributeValues[":notificationStatus"] = "pending";
    }

    await docClient.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: { PK: `NOTICE#${body.noticeId}`, SK: "#META" },
        UpdateExpression: `SET ${setExpressions.join(", ")}`,
        ExpressionAttributeNames: { "#status": "status" },
        ExpressionAttributeValues: expressionAttributeValues,
      }),
    );

    return NextResponse.json({ success: true });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "공지 수정에 실패했습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const noticeId = searchParams.get("noticeId");
    if (!noticeId) {
      return NextResponse.json({ error: "noticeId가 필요합니다." }, { status: 400 });
    }

    await docClient.send(
      new DeleteCommand({
        TableName: TABLE_NAME,
        Key: { PK: `NOTICE#${noticeId}`, SK: "#META" },
      }),
    );

    return NextResponse.json({ success: true });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "공지 삭제에 실패했습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
```

Do not reset `notifiedAt` on edit, unpublish, or re-publish. The stream worker relies on `notifiedAt` staying present to prevent duplicate SNS fan-out.

- [ ] **Step 2: Build admin**

Run:

```bash
cd woncheon-admin
pnpm build
```

Expected:

```text
Compiled successfully
```

- [ ] **Step 3: Commit**

```bash
git add woncheon-admin/src/app/api/admin/notices/route.ts
git commit -m "feat: add admin notice api"
```

---

## Task 5: Admin Notice Management Page

**Files:**
- Create: `woncheon-admin/src/app/(admin)/notices/page.tsx`
- Modify: `woncheon-admin/src/components/layout/sidebar.tsx`

- [ ] **Step 1: Add sidebar item**

Modify imports in `woncheon-admin/src/components/layout/sidebar.tsx`:

```ts
import {
  LayoutDashboard,
  Users,
  CalendarCheck,
  Heart,
  FolderKanban,
  UserPlus,
  LogOut,
  Flag,
  Megaphone,
} from "lucide-react";
```

Add the item after 중보기도:

```ts
{ href: "/notices", label: "공지사항", icon: Megaphone },
```

- [ ] **Step 2: Create admin notices page**

Create `woncheon-admin/src/app/(admin)/notices/page.tsx`:

```tsx
"use client";

import { useEffect, useState } from "react";
import { format } from "date-fns";
import { ko } from "date-fns/locale";
import { Megaphone, Pencil, RefreshCw, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

interface Notice {
  noticeId: string;
  title: string;
  content: string;
  status: "draft" | "published";
  pinned: boolean;
  createdAt: string;
  updatedAt: string;
  publishedAt: string | null;
}

const emptyForm = {
  title: "",
  content: "",
  status: "draft" as "draft" | "published",
  pinned: false,
};

export default function NoticesPage() {
  const [notices, setNotices] = useState<Notice[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<Notice | null>(null);
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<Notice | null>(null);
  const [form, setForm] = useState(emptyForm);

  async function loadNotices() {
    setLoading(true);
    try {
      const res = await fetch("/api/admin/notices", { credentials: "include" });
      const data = await res.json();
      setNotices(data.notices ?? []);
    } catch {
      toast.error("공지 목록을 불러올 수 없습니다.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadNotices();
  }, []);

  function openCreate() {
    setEditing(null);
    setForm(emptyForm);
    setDialogOpen(true);
  }

  function openEdit(notice: Notice) {
    setEditing(notice);
    setForm({
      title: notice.title,
      content: notice.content,
      status: notice.status,
      pinned: notice.pinned,
    });
    setDialogOpen(true);
  }

  async function saveNotice() {
    setSaving(true);
    try {
      const res = await fetch("/api/admin/notices", {
        method: editing ? "PUT" : "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          noticeId: editing?.noticeId,
          title: form.title,
          content: form.content,
          status: form.status,
          pinned: form.pinned,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        toast.error(data.error ?? "저장에 실패했습니다.");
        return;
      }
      toast.success(editing ? "공지사항이 수정되었습니다." : "공지사항이 생성되었습니다.");
      setDialogOpen(false);
      await loadNotices();
    } catch {
      toast.error("저장에 실패했습니다.");
    } finally {
      setSaving(false);
    }
  }

  async function deleteNotice() {
    if (!deleteTarget) return;
    try {
      const res = await fetch(`/api/admin/notices?noticeId=${deleteTarget.noticeId}`, {
        method: "DELETE",
        credentials: "include",
      });
      if (!res.ok) {
        toast.error("삭제에 실패했습니다.");
        return;
      }
      toast.success("공지사항이 삭제되었습니다.");
      setDeleteTarget(null);
      await loadNotices();
    } catch {
      toast.error("삭제에 실패했습니다.");
    }
  }

  const publishedCount = notices.filter((n) => n.status === "published").length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">공지사항</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            전체 {notices.length}개 · 게시 중 {publishedCount}개
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={loadNotices} className="gap-2">
            <RefreshCw className="w-4 h-4" />
            새로고침
          </Button>
          <Button onClick={openCreate} className="gap-2">
            <Megaphone className="w-4 h-4" />
            공지 작성
          </Button>
        </div>
      </div>

      <Card className="border-0 shadow-sm">
        <CardHeader className="pb-2">
          <h2 className="text-lg font-semibold">공지 목록</h2>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>제목</TableHead>
                <TableHead className="w-[120px]">상태</TableHead>
                <TableHead className="w-[150px]">게시일</TableHead>
                <TableHead className="w-[110px] text-right">관리</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={4} className="text-center py-10 text-slate-400">
                    불러오는 중...
                  </TableCell>
                </TableRow>
              ) : notices.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} className="text-center py-10 text-slate-400">
                    등록된 공지사항이 없습니다.
                  </TableCell>
                </TableRow>
              ) : (
                notices.map((notice) => (
                  <TableRow key={notice.noticeId}>
                    <TableCell>
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="font-medium">{notice.title}</span>
                          {notice.pinned && <Badge variant="outline">고정</Badge>}
                        </div>
                        <p className="max-w-xl truncate text-xs text-slate-500">
                          {notice.content}
                        </p>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline" className={notice.status === "published" ? "text-emerald-600 border-emerald-300" : ""}>
                        {notice.status === "published" ? "게시 중" : "초안"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-xs text-slate-500">
                      {notice.publishedAt
                        ? format(new Date(notice.publishedAt), "M/d (E) HH:mm", { locale: ko })
                        : "-"}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="icon" onClick={() => openEdit(notice)}>
                        <Pencil className="w-4 h-4" />
                      </Button>
                      <Button variant="ghost" size="icon" className="text-slate-400 hover:text-red-500" onClick={() => setDeleteTarget(notice)}>
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle>{editing ? "공지 수정" : "공지 작성"}</DialogTitle>
            <DialogDescription>
              게시 중으로 저장하면 앱 공지사항 화면에 바로 노출됩니다.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="title">제목</Label>
              <Input id="title" value={form.title} onChange={(e) => setForm((prev) => ({ ...prev, title: e.target.value }))} maxLength={80} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="content">내용</Label>
              <textarea
                id="content"
                value={form.content}
                onChange={(e) => setForm((prev) => ({ ...prev, content: e.target.value }))}
                className="min-h-56 w-full rounded-md border border-slate-200 bg-transparent px-3 py-2 text-sm outline-none focus-visible:ring-2 focus-visible:ring-slate-950 dark:border-slate-800 dark:focus-visible:ring-slate-300"
                maxLength={3000}
              />
            </div>
            <div className="flex items-center gap-6">
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" checked={form.pinned} onChange={(e) => setForm((prev) => ({ ...prev, pinned: e.target.checked }))} />
                고정 표시
              </label>
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" checked={form.status === "published"} onChange={(e) => setForm((prev) => ({ ...prev, status: e.target.checked ? "published" : "draft" }))} />
                게시 중
              </label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>취소</Button>
            <Button onClick={saveNotice} disabled={saving}>{saving ? "저장 중..." : "저장"}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!deleteTarget} onOpenChange={() => setDeleteTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>공지 삭제</DialogTitle>
            <DialogDescription>삭제된 공지는 앱에서 더 이상 볼 수 없습니다.</DialogDescription>
          </DialogHeader>
          <div className="rounded-lg bg-slate-50 p-3 text-sm dark:bg-slate-900">
            <p className="font-medium">{deleteTarget?.title}</p>
            <p className="line-clamp-3 text-slate-500">{deleteTarget?.content}</p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteTarget(null)}>취소</Button>
            <Button variant="destructive" onClick={deleteNotice}>삭제</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
```

- [ ] **Step 3: Build admin**

Run:

```bash
cd woncheon-admin
pnpm build
```

Expected:

```text
Compiled successfully
```

- [ ] **Step 4: Commit**

```bash
git add 'woncheon-admin/src/app/(admin)/notices/page.tsx' woncheon-admin/src/components/layout/sidebar.tsx
git commit -m "feat: add admin notices page"
```

---

## Task 6: Flutter Notice Model and Repository

**Files:**
- Create: `lib/features/notice/domain/notice_model.dart`
- Create after generator: `lib/features/notice/domain/notice_model.freezed.dart`
- Create after generator: `lib/features/notice/domain/notice_model.g.dart`
- Create: `lib/features/notice/data/notice_repository.dart`
- Modify: `lib/core/api/endpoints.dart`

- [ ] **Step 1: Add endpoint constants**

Modify `lib/core/api/endpoints.dart` after attendance endpoints:

```dart
  // Notices
  static const String notices = '/notices';
  static String notice(String noticeId) => '/notices/$noticeId';
```

- [ ] **Step 2: Create notice models**

Create `lib/features/notice/domain/notice_model.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notice_model.freezed.dart';
part 'notice_model.g.dart';

@freezed
class NoticeItem with _$NoticeItem {
  const factory NoticeItem({
    required String noticeId,
    required String title,
    required String contentPreview,
    required bool pinned,
    required String publishedAt,
  }) = _NoticeItem;

  factory NoticeItem.fromJson(Map<String, dynamic> json) =>
      _$NoticeItemFromJson(json);
}

@freezed
class NoticeDetail with _$NoticeDetail {
  const factory NoticeDetail({
    required String noticeId,
    required String title,
    required String content,
    required bool pinned,
    required String publishedAt,
  }) = _NoticeDetail;

  factory NoticeDetail.fromJson(Map<String, dynamic> json) =>
      _$NoticeDetailFromJson(json);
}

@freezed
class NoticeListResponse with _$NoticeListResponse {
  const factory NoticeListResponse({
    required List<NoticeItem> items,
    required bool hasMore,
    String? nextCursor,
  }) = _NoticeListResponse;

  factory NoticeListResponse.fromJson(Map<String, dynamic> json) =>
      _$NoticeListResponseFromJson(json);
}
```

- [ ] **Step 3: Generate model code**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected:

```text
Built with build_runner
```

- [ ] **Step 4: Create repository**

Create `lib/features/notice/data/notice_repository.dart`:

```dart
import 'package:woncheon_youth/core/api/api_client.dart';
import 'package:woncheon_youth/core/api/endpoints.dart';
import 'package:woncheon_youth/core/constants.dart';
import 'package:woncheon_youth/features/notice/domain/notice_model.dart';

class NoticeRepository {
  NoticeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<NoticeListResponse> listNotices({
    int limit = AppConstants.defaultPageSize,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (cursor != null) queryParams['cursor'] = cursor;

    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.notices,
      queryParameters: queryParams,
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return NoticeListResponse.fromJson(data);
  }

  Future<NoticeDetail> getNotice(String noticeId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      Endpoints.notice(noticeId),
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return NoticeDetail.fromJson(data);
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/api/endpoints.dart lib/features/notice/domain/notice_model.dart lib/features/notice/domain/notice_model.freezed.dart lib/features/notice/domain/notice_model.g.dart lib/features/notice/data/notice_repository.dart
git commit -m "feat: add notice app data layer"
```

---

## Task 7: Flutter Notice Providers

**Files:**
- Create: `lib/features/notice/presentation/notice_providers.dart`

- [ ] **Step 1: Create providers**

Create `lib/features/notice/presentation/notice_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/features/notice/data/notice_repository.dart';
import 'package:woncheon_youth/features/notice/domain/notice_model.dart';
import 'package:woncheon_youth/shared/providers/providers.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return NoticeRepository(ref.watch(apiClientProvider));
});

final noticeListProvider =
    AsyncNotifierProvider<NoticeListNotifier, NoticeListResponse>(
  NoticeListNotifier.new,
);

class NoticeListNotifier extends AsyncNotifier<NoticeListResponse> {
  @override
  Future<NoticeListResponse> build() {
    return ref.read(noticeRepositoryProvider).listNotices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(noticeRepositoryProvider).listNotices(),
    );
  }
}

final noticeDetailProvider =
    FutureProvider.family<NoticeDetail, String>((ref, noticeId) {
  return ref.read(noticeRepositoryProvider).getNotice(noticeId);
});
```

- [ ] **Step 2: Format and analyze**

Run:

```bash
dart format lib/features/notice/presentation/notice_providers.dart
flutter analyze
```

Expected:

```text
No new errors. Existing info-level lint backlog may remain.
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/notice/presentation/notice_providers.dart
git commit -m "feat: add notice providers"
```

---

## Task 8: Flutter Notice List and Detail Screens

**Files:**
- Create: `test/features/notice/presentation/notice_list_page_test.dart`
- Create: `lib/features/notice/presentation/notice_list_page.dart`
- Create: `lib/features/notice/presentation/notice_detail_page.dart`

- [ ] **Step 1: Write list page widget test**

Create `test/features/notice/presentation/notice_list_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/notice/domain/notice_model.dart';
import 'package:woncheon_youth/features/notice/presentation/notice_list_page.dart';

void main() {
  testWidgets('NoticeCard renders title and preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NoticeCard(
            notice: const NoticeItem(
              noticeId: 'N1',
              title: '이번 주 청년부 안내',
              contentPreview: '금요 성령집회 후 청년부 모임이 있습니다.',
              pinned: true,
              publishedAt: '2026-07-03T01:20:00.000Z',
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('이번 주 청년부 안내'), findsOneWidget);
    expect(find.text('금요 성령집회 후 청년부 모임이 있습니다.'), findsOneWidget);
    expect(find.text('고정'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/features/notice/presentation/notice_list_page_test.dart
```

Expected:

```text
FAIL with "NoticeCard not found"
```

- [ ] **Step 3: Create notice list page**

Create `lib/features/notice/presentation/notice_list_page.dart`:

```dart
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woncheon_youth/core/router/app_router.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/notice/domain/notice_model.dart';
import 'package:woncheon_youth/features/notice/presentation/notice_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class NoticeListPage extends ConsumerWidget {
  const NoticeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noticeListProvider);
    return WCPageScaffold(
      header: const WCHeader(title: '공지사항', subtitle: '청년부 소식을 확인해요'),
      contentPadding: EdgeInsets.zero,
      child: state.when(
        loading: () => const WCLoadingView(label: '공지사항을 불러오는 중'),
        error: (_, __) => WCStateView(
          icon: FluentIcons.error_circle_24_regular,
          title: '공지사항을 불러올 수 없습니다',
          message: '잠시 후 다시 시도해주세요.',
          actionLabel: '다시 시도',
          onAction: () => ref.read(noticeListProvider.notifier).refresh(),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return const WCStateView(
              icon: FluentIcons.megaphone_24_regular,
              title: '아직 공지사항이 없어요',
              message: '새 공지가 올라오면 이곳에서 확인할 수 있습니다.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(noticeListProvider.notifier).refresh(),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: WCSpacing.pageX),
              itemCount: data.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: WCSpacing.xs),
              itemBuilder: (context, index) {
                final notice = data.items[index];
                return NoticeCard(
                  notice: notice,
                  onTap: () {
                    Haptic.selection();
                    context.push(AppRoutes.noticeDetail(notice.noticeId));
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({required this.notice, required this.onTap, super.key});

  final NoticeItem notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wc = context.wc;
    final date = DateTime.tryParse(notice.publishedAt);
    final dateLabel = date != null ? formatRelative(date) : '';
    return WCCard(
      onTap: onTap,
      density: WCCardDensity.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (notice.pinned)
                const WCPill(
                  tone: WCPillTone.accent,
                  small: true,
                  child: Text('고정'),
                ),
              if (notice.pinned) const SizedBox(width: WCSpacing.xs),
              Expanded(
                child: Text(
                  notice.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: wc.text,
                  ),
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 11.5, color: wc.textTer),
                ),
            ],
          ),
          const SizedBox(height: WCSpacing.xs),
          Text(
            notice.contentPreview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: wc.textSec,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create notice detail page**

Create `lib/features/notice/presentation/notice_detail_page.dart`:

```dart
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/notice/presentation/notice_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';
import 'package:woncheon_youth/shared/widgets/wc_widgets.dart';

class NoticeDetailPage extends ConsumerWidget {
  const NoticeDetailPage({required this.noticeId, super.key});

  final String noticeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(noticeDetailProvider(noticeId));
    return Scaffold(
      backgroundColor: context.wc.bg,
      body: SafeArea(
        child: async.when(
          loading: () => const WCLoadingView(label: '공지사항을 불러오는 중'),
          error: (_, __) => WCStateView(
            icon: FluentIcons.error_circle_24_regular,
            title: '공지사항을 불러올 수 없습니다',
            actionLabel: '뒤로가기',
            onAction: () => Navigator.of(context).pop(),
          ),
          data: (notice) {
            final wc = context.wc;
            final date = DateTime.tryParse(notice.publishedAt);
            final dateLabel = date != null ? formatRelative(date) : '';
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      WCSpacing.pageX,
                      WCSpacing.sm,
                      WCSpacing.pageX,
                      WCSpacing.md,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '뒤로가기',
                          onPressed: () {
                            Haptic.selection();
                            Navigator.of(context).pop();
                          },
                          icon: Icon(FluentIcons.chevron_left_24_regular, color: wc.text),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: WCSpacing.pageX),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notice.pinned)
                          const WCPill(
                            tone: WCPillTone.accent,
                            child: Text('고정 공지'),
                          ),
                        if (notice.pinned) const SizedBox(height: WCSpacing.sm),
                        Text(
                          notice.title,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: wc.text,
                            height: 1.25,
                          ),
                        ),
                        if (dateLabel.isNotEmpty) ...[
                          const SizedBox(height: WCSpacing.sm),
                          Text(
                            dateLabel,
                            style: TextStyle(fontSize: 12.5, color: wc.textTer),
                          ),
                        ],
                        const SizedBox(height: WCSpacing.xl),
                        Text(
                          notice.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: wc.textSec,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: WCSpacing.bottomNavClearance),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run list page test**

Run:

```bash
flutter test test/features/notice/presentation/notice_list_page_test.dart
```

Expected:

```text
All tests passed
```

- [ ] **Step 6: Commit**

```bash
git add test/features/notice/presentation/notice_list_page_test.dart lib/features/notice/presentation/notice_list_page.dart lib/features/notice/presentation/notice_detail_page.dart
git commit -m "feat: add notice app screens"
```

---

## Task 9: Flutter Routing and Home Tile

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/home/presentation/home_page.dart`

- [ ] **Step 1: Add routes**

Modify imports in `lib/core/router/app_router.dart`:

```dart
import 'package:woncheon_youth/features/notice/presentation/notice_detail_page.dart';
import 'package:woncheon_youth/features/notice/presentation/notice_list_page.dart';
```

Add route constants:

```dart
  static const notices = '/notices';
  static String noticeDetail(String id) => '/notices/$id';
```

Add root-level routes before `StatefulShellRoute.indexedStack`:

```dart
      GoRoute(
        path: AppRoutes.notices,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NoticeListPage(),
        routes: [
          GoRoute(
            path: ':noticeId',
            parentNavigatorKey: _rootKey,
            builder: (_, state) => NoticeDetailPage(
              noticeId: state.pathParameters['noticeId']!,
            ),
          ),
        ],
      ),
```

- [ ] **Step 2: Enable the Home notice tile**

Modify the `공지사항` `WCActionTile` in `lib/features/home/presentation/home_page.dart`:

```dart
Expanded(
  child: WCActionTile(
    icon: FluentIcons.megaphone_24_regular,
    title: '공지사항',
    subtitle: '청년부 소식',
    onTap: () {
      Haptic.light();
      context.push(AppRoutes.notices);
    },
  ),
),
```

- [ ] **Step 3: Format and test**

Run:

```bash
dart format lib/core/router/app_router.dart lib/features/home/presentation/home_page.dart
flutter test
```

Expected:

```text
All tests passed
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/app_router.dart lib/features/home/presentation/home_page.dart
git commit -m "feat: route home notice tile"
```

---

## Task 10: Verification and Manual QA

**Files:**
- No source files.

- [ ] **Step 1: Run Flutter verification**

Run:

```bash
flutter test
flutter analyze
flutter build apk --debug
flutter build ios --debug --no-codesign
```

Expected:

```text
flutter test: All tests passed
flutter analyze: no errors/warnings; existing info-level lint backlog may remain
Android debug build: Built build/app/outputs/flutter-apk/app-debug.apk
iOS debug build: Built build/ios/iphoneos/Runner.app
```

- [ ] **Step 2: Run backend verification**

Run:

```bash
cd woncheon-backend
pnpm test
pnpm sls package --stage dev
```

Expected:

```text
Vitest tests pass
Serverless package succeeds
```

Confirm the packaged CloudFormation includes these infra changes:
- Existing DynamoDB table `woncheon-dev` receives `StreamSpecification: NEW_AND_OLD_IMAGES`.
- New Lambda function for `sendNoticeNotification`.
- New DynamoDB Stream event source mapping.
- New API Gateway routes for `GET /notices` and `GET /notices/{noticeId}`.
- No new DynamoDB table, no new GSI, no new SNS Platform Application.

- [ ] **Step 3: Run admin verification**

Run:

```bash
cd woncheon-admin
pnpm build
```

Expected:

```text
Compiled successfully
```

- [ ] **Step 4: Manual QA with local/dev backend**

1. Deploy backend to dev:

```bash
cd woncheon-backend
AWS_PROFILE=dongik2 pnpm sls deploy --stage dev
```

Expected AWS target:
- Account: `863518440691`
- Region: `ap-northeast-2`
- Stage: `dev`
- Stack/service: `woncheon-backend`
- Existing table: `woncheon-dev`

2. Start admin:

```bash
cd woncheon-admin
pnpm dev
```

3. In admin:
- Open `/notices`.
- Create draft notice.
- Confirm draft appears in admin.
- Confirm no device receives a push for draft creation.
- Publish the notice.
- Confirm status changes to `게시 중`.
- Confirm one SNS push is received on registered devices.
- Edit the published notice title/body.
- Confirm no additional push is received.
- Unpublish and re-publish the same notice.
- Confirm no additional push is received because `notifiedAt` remains set.

4. In Flutter app:
- Run the app.
- Tap Home `공지사항`.
- Confirm published notice appears.
- Tap notice.
- Confirm detail page shows title/content.

- [ ] **Step 5: Commit final verification note**

If no source changes are needed after QA:

```bash
git status --short
```

Expected:

```text
No unexpected files except build artifacts ignored by git
```

---

## Self-Review

Spec coverage:
- Admin CRUD: Task 4 and Task 5.
- App read-only list/detail: Task 2, Task 6, Task 7, Task 8, Task 9.
- Existing Home tile activation: Task 9.
- Backend storage and indexes: DynamoDB shape section and Task 2/3/4.
- First-publish-only SNS push: DynamoDB shape section and Task 1/3/4/10.
- Verification: Task 10.

Scope check:
- Push notifications are included only for first-time publish and are guarded by `notifiedAt`.
- Duplicate notification paths are excluded intentionally: no push on edit, unpublish, or re-publish.
- Manual resend and audience targeting are excluded intentionally to avoid accidental broadcast behavior.
- Rich text and attachments are excluded intentionally to keep v1 shippable.
- Store release commands are intentionally excluded from this implementation plan. After the feature passes QA, use the separate iOS/Android release runbook for version bumping and store uploads.

Placeholder scan:
- No `TBD`, `TODO`, or open-ended implementation placeholders are present.

Type consistency:
- Backend uses `noticeId`, `title`, `content`, `status`, `pinned`, `createdAt`, `updatedAt`, `publishedAt`, `notifiedAt`, `notificationStatus`, and notification delivery counts.
- Flutter model uses `noticeId`, `title`, `contentPreview`, `content`, `pinned`, `publishedAt`.
- Admin API returns the same fields consumed by admin page.
