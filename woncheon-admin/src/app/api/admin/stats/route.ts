import { NextResponse } from "next/server";
import { ScanCommand } from "@aws-sdk/lib-dynamodb";
import { docClient, TABLE_NAME } from "@/lib/db/dynamo";
import { getPool } from "@/lib/db/pg";

// Auth is handled by middleware — no duplicate check needed here
export async function GET() {
  try {
    const memberScan = await docClient.send(
      new ScanCommand({
        TableName: TABLE_NAME,
        FilterExpression: "SK = :sk AND begins_with(PK, :pk)",
        ExpressionAttributeValues: { ":sk": "#META", ":pk": "MEMBER#" },
        Select: "COUNT",
      })
    );

    const prayerScan = await docClient.send(
      new ScanCommand({
        TableName: TABLE_NAME,
        FilterExpression: "SK = :sk AND begins_with(PK, :pk)",
        ExpressionAttributeValues: { ":sk": "#META", ":pk": "PRAYER#" },
        Select: "COUNT",
      })
    );

    const pool = getPool();
    const groupCount = await pool.query<{ count: string }>(
      "SELECT COUNT(*)::text AS count FROM groups"
    );
    const attendanceRate = await pool.query<{ rate: string }>(
      `SELECT
         CASE WHEN COUNT(*) > 0
           THEN ROUND(COUNT(CASE WHEN is_present THEN 1 END)::numeric / COUNT(*)::numeric * 100, 1)::text
           ELSE '0'
         END AS rate
       FROM attendance
       WHERE attendance_date >= DATE_TRUNC('month', CURRENT_DATE)`
    );

    return NextResponse.json({
      memberCount: memberScan.Count ?? 0,
      prayerCount: prayerScan.Count ?? 0,
      groupCount: Number(groupCount.rows[0]?.count ?? 0),
      monthlyAttendanceRate: Number(attendanceRate.rows[0]?.rate ?? 0),
    });
  } catch (error: unknown) {
    console.error("[stats] Failed to load stats:", error);
    return NextResponse.json(
      { error: "통계를 불러올 수 없습니다." },
      { status: 500 }
    );
  }
}
