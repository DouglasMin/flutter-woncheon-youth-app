import { NextResponse } from "next/server";
import { ScanCommand, UpdateCommand, PutCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "@/lib/db/dynamo";
import bcrypt from "bcryptjs";
import { ulid } from "ulid";

const DEFAULT_PASSWORD = "woncheon2025";

// GET — 가입 요청 목록 조회
export async function GET() {
  try {
    const result = await docClient.send(
      new ScanCommand({
        TableName: TABLE_NAME,
        FilterExpression: "begins_with(PK, :pk) AND SK = :sk",
        ExpressionAttributeValues: {
          ":pk": "REGISTER_REQUEST#",
          ":sk": "#META",
        },
      })
    );

    const requests = (result.Items ?? [])
      .map((item) => ({
        requestId: item.requestId,
        name: item.name,
        phone: item.phone,
        note: item.note ?? "",
        status: item.status,
        createdAt: item.createdAt,
      }))
      .sort(
        (a, b) =>
          new Date(b.createdAt as string).getTime() -
          new Date(a.createdAt as string).getTime()
      );

    return NextResponse.json({ requests });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "요청 목록을 불러올 수 없습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

// POST — 가입 요청 승인/거부
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { requestId, action } = body as {
      requestId?: string;
      action?: "approve" | "reject";
    };

    if (!requestId || !action || !["approve", "reject"].includes(action)) {
      return NextResponse.json(
        { error: "requestId와 action(approve/reject)이 필요합니다." },
        { status: 400 }
      );
    }

    // Update request status
    await docClient.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: { PK: `REGISTER_REQUEST#${requestId}`, SK: "#META" },
        UpdateExpression: "SET #s = :status, processedAt = :now",
        ExpressionAttributeNames: { "#s": "status" },
        ExpressionAttributeValues: {
          ":status": action === "approve" ? "approved" : "rejected",
          ":now": new Date().toISOString(),
        },
      })
    );

    // If approved, create member account
    if (action === "approve") {
      // Get request details
      const reqResult = await docClient.send(
        new ScanCommand({
          TableName: TABLE_NAME,
          FilterExpression: "PK = :pk AND SK = :sk",
          ExpressionAttributeValues: {
            ":pk": `REGISTER_REQUEST#${requestId}`,
            ":sk": "#META",
          },
        })
      );

      const req = reqResult.Items?.[0];
      if (!req) {
        return NextResponse.json(
          { error: "요청을 찾을 수 없습니다." },
          { status: 404 }
        );
      }

      // Check duplicate name
      const existing = await docClient.send(
        new QueryCommand({
          TableName: TABLE_NAME,
          IndexName: "GSI1",
          KeyConditionExpression: "GSI1PK = :pk AND GSI1SK = :sk",
          ExpressionAttributeValues: {
            ":pk": `NAME#${req.name as string}`,
            ":sk": "#META",
          },
        })
      );

      if ((existing.Count ?? 0) > 0) {
        return NextResponse.json(
          { error: "이미 등록된 이름입니다." },
          { status: 409 }
        );
      }

      const memberId = ulid();
      const passwordHash = await bcrypt.hash(DEFAULT_PASSWORD, 10);
      const now = new Date().toISOString();

      await docClient.send(
        new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `MEMBER#${memberId}`,
            SK: "#META",
            GSI1PK: `NAME#${req.name as string}`,
            GSI1SK: "#META",
            memberId,
            name: req.name,
            passwordHash,
            isFirstLogin: true,
            birthDate: "",
            gender: "",
            createdAt: now,
            updatedAt: now,
          },
        })
      );

      return NextResponse.json({
        success: true,
        action: "approved",
        memberId,
        name: req.name,
      });
    }

    return NextResponse.json({ success: true, action: "rejected" });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "처리에 실패했습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
