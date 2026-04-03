import { NextResponse } from "next/server";
import { ScanCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "@/lib/db/dynamo";
import { getPool } from "@/lib/db/pg";

export async function GET() {
  try {
    // DynamoDB: all members
    const result = await docClient.send(
      new ScanCommand({
        TableName: TABLE_NAME,
        FilterExpression: "SK = :sk AND begins_with(PK, :pk)",
        ExpressionAttributeValues: { ":sk": "#META", ":pk": "MEMBER#" },
        ProjectionExpression:
          "memberId, #n, isFirstLogin, createdAt, birthDate, gender",
        ExpressionAttributeNames: { "#n": "name" },
      })
    );

    // PostgreSQL: member → group mapping
    const pool = getPool();
    const groupMap = await pool.query(
      `SELECT gm.member_id, g.name AS group_name
       FROM group_members gm JOIN groups g ON gm.group_id = g.id`
    );
    const memberGroups = new Map<string, string>();
    for (const row of groupMap.rows) {
      memberGroups.set(row.member_id, row.group_name);
    }

    const members = (result.Items ?? []).map((item) => ({
      memberId: item.memberId,
      name: item.name,
      isFirstLogin: item.isFirstLogin ?? true,
      createdAt: item.createdAt,
      birthDate: item.birthDate ?? "",
      gender: item.gender ?? "",
      groupName: memberGroups.get(item.memberId as string) ?? "미배정",
    }));

    members.sort((a, b) =>
      (a.name as string).localeCompare(b.name as string, "ko")
    );

    return NextResponse.json({ members });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "회원 목록을 불러올 수 없습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
