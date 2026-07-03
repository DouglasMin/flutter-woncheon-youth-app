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

    // PostgreSQL: member → group mapping (id + name) + 목자 여부
    const pool = getPool();
    const groupMap = await pool.query(
      `SELECT gm.member_id,
              g.id AS group_id,
              g.name AS group_name,
              (g.leader_member_id = gm.member_id) AS is_leader
       FROM group_members gm JOIN groups g ON gm.group_id = g.id`
    );
    const memberGroups = new Map<
      string,
      { groupId: number; groupName: string; isLeader: boolean }
    >();
    for (const row of groupMap.rows) {
      memberGroups.set(row.member_id, {
        groupId: Number(row.group_id),
        groupName: row.group_name,
        isLeader: row.is_leader === true,
      });
    }

    // 전체 목장 목록 (이동 dropdown용)
    const allGroupsResult = await pool.query(
      "SELECT id, name FROM groups ORDER BY name"
    );
    const allGroups = allGroupsResult.rows.map((r) => ({
      id: Number(r.id),
      name: r.name,
    }));

    const members = (result.Items ?? []).map((item) => {
      const g = memberGroups.get(item.memberId as string);
      return {
        memberId: item.memberId,
        name: item.name,
        isFirstLogin: item.isFirstLogin ?? true,
        createdAt: item.createdAt,
        birthDate: item.birthDate ?? "",
        gender: item.gender ?? "",
        groupId: g?.groupId ?? null,
        groupName: g?.groupName ?? "미배정",
        isLeader: g?.isLeader ?? false,
      };
    });

    members.sort((a, b) =>
      (a.name as string).localeCompare(b.name as string, "ko")
    );

    return NextResponse.json({ members, allGroups });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "회원 목록을 불러올 수 없습니다.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
