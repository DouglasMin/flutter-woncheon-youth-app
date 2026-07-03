import { NextResponse } from "next/server";
import {
  DeleteCommand,
  GetCommand,
  PutCommand,
  QueryCommand,
  UpdateCommand,
} from "@aws-sdk/lib-dynamodb";
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
  if (!body.title || body.title.trim().length === 0) {
    return "제목을 입력해주세요.";
  }
  if (body.title.length > 80) {
    return "제목은 80자 이내로 입력해주세요.";
  }
  if (!body.content || body.content.trim().length === 0) {
    return "내용을 입력해주세요.";
  }
  if (body.content.length > 3000) {
    return "내용은 3000자 이내로 입력해주세요.";
  }
  if (body.status && !["draft", "published"].includes(body.status)) {
    return "status는 draft 또는 published여야 합니다.";
  }
  return null;
}

function normalizeStatus(status: NoticeInput["status"]): NoticeStatus {
  return status === "published" ? "published" : "draft";
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
    const message =
      error instanceof Error ? error.message : "공지 목록을 불러올 수 없습니다.";
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
    const status = normalizeStatus(body.status);
    const publishedAt = status === "published" ? now : undefined;
    const sortAt = publishedAt ?? now;

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
          notificationStatus: status === "published" ? "pending" : undefined,
        },
      }),
    );

    return NextResponse.json({ success: true, noticeId }, { status: 201 });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "공지 생성에 실패했습니다.";
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
      return NextResponse.json(
        { error: "존재하지 않는 공지입니다." },
        { status: 404 },
      );
    }

    const now = new Date().toISOString();
    const nextStatus = normalizeStatus(body.status);
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
    ];
    const removeExpressions: string[] = [];
    const expressionAttributeValues: Record<string, unknown> = {
      ":gsi2sk": `${sortAt}#${body.noticeId}`,
      ":title": body.title!.trim(),
      ":content": body.content!.trim(),
      ":status": nextStatus,
      ":pinned": body.pinned ?? false,
      ":updatedAt": now,
    };

    if (nextPublishedAt) {
      setExpressions.push("publishedAt = :publishedAt");
      expressionAttributeValues[":publishedAt"] = nextPublishedAt;
    } else {
      removeExpressions.push("publishedAt");
    }

    if (shouldQueueNotification) {
      setExpressions.push("notificationStatus = :notificationStatus");
      expressionAttributeValues[":notificationStatus"] = "pending";
    }

    const updateExpression = [
      `SET ${setExpressions.join(", ")}`,
      removeExpressions.length > 0 ? `REMOVE ${removeExpressions.join(", ")}` : "",
    ]
      .filter(Boolean)
      .join(" ");

    await docClient.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: { PK: `NOTICE#${body.noticeId}`, SK: "#META" },
        UpdateExpression: updateExpression,
        ExpressionAttributeNames: { "#status": "status" },
        ExpressionAttributeValues: expressionAttributeValues,
      }),
    );

    return NextResponse.json({ success: true });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "공지 수정에 실패했습니다.";
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
    const message =
      error instanceof Error ? error.message : "공지 삭제에 실패했습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
