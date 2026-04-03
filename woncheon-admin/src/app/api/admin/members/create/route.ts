import { NextResponse } from "next/server";
import { PutCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "@/lib/db/dynamo";
import { getPool } from "@/lib/db/pg";
import bcrypt from "bcryptjs";
import { ulid } from "ulid";

const DEFAULT_PASSWORD = "woncheon2025";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { name, birthDate, gender, groupId } = body as {
      name?: string;
      birthDate?: string;
      gender?: string;
      groupId?: number;
    };

    if (!name || name.trim().length === 0) {
      return NextResponse.json(
        { error: "이름을 입력해주세요." },
        { status: 400 }
      );
    }

    // Check duplicate name
    const existing = await docClient.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        IndexName: "GSI1",
        KeyConditionExpression: "GSI1PK = :pk AND GSI1SK = :sk",
        ExpressionAttributeValues: {
          ":pk": `NAME#${name.trim()}`,
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

    // DynamoDB 회원 등록
    await docClient.send(
      new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `MEMBER#${memberId}`,
          SK: "#META",
          GSI1PK: `NAME#${name.trim()}`,
          GSI1SK: "#META",
          memberId,
          name: name.trim(),
          passwordHash,
          isFirstLogin: true,
          birthDate: birthDate ?? "",
          gender: gender ?? "",
          createdAt: now,
          updatedAt: now,
        },
      })
    );

    // PostgreSQL 목장 배정
    if (groupId) {
      const pool = getPool();
      await pool.query(
        `INSERT INTO group_members (group_id, member_id, member_name)
         VALUES ($1, $2, $3)
         ON CONFLICT DO NOTHING`,
        [groupId, memberId, name.trim()]
      );
    }

    return NextResponse.json({
      success: true,
      memberId,
      name: name.trim(),
    });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "회원 등록에 실패했습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
